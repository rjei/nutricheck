import 'package:flutter/foundation.dart';

import '../data/datasources/ai_chat_data_source.dart';
import '../data/models/additive.dart';
import '../data/models/product_analysis.dart';
import '../data/repositories/additive_repository.dart';
import '../data/repositories/product_repository.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';
import 'home_data_service.dart';

/// Service pengelola Chat AI NutriCheck berbasis [ChangeNotifier].
///
/// Menggabungkan LLM ([AiChatDataSource]) dengan data terverifikasi dari
/// [AdditiveRepository] dan [ProductRepository] agar AI dapat menjelaskan
/// zat aditif secara akurat serta mencarikan alternatif produk Indonesia
/// yang lebih sehat.
class AiChatService extends ChangeNotifier {
  AiChatService({
    AiChatDataSource? dataSource,
    AdditiveRepository? additiveRepository,
    ProductRepository? productRepository,
    AuthService? authService,
    HomeDataService? homeDataService,
  })  : _dataSource = dataSource ?? _resolveDefaultDataSource(),
        _additives = additiveRepository ?? AdditiveRepository.instance,
        _products = productRepository ?? ProductRepository.instance,
        _auth = authService ?? AuthService(),
        _homeData = homeDataService ?? HomeDataService.instance;

  static AiChatDataSource _resolveDefaultDataSource() {
    final groq = GroqAiChatDataSource();
    if (groq.isConfigured) return groq;

    const geminiOrGroqKey = String.fromEnvironment('GEMINI_API_KEY');
    if (geminiOrGroqKey.trim().startsWith('gsk_')) {
      return GroqAiChatDataSource(apiKey: geminiOrGroqKey);
    }
    return GeminiAiChatDataSource();
  }

  static final AiChatService instance = AiChatService();

  final AiChatDataSource _dataSource;
  final AdditiveRepository _additives;
  final ProductRepository _products;
  final AuthService _auth;
  final HomeDataService _homeData;

  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  ProductAnalysis? _activeProductContext;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  ProductAnalysis? get activeProductContext => _activeProductContext;
  bool get isRemoteAiConfigured => _dataSource.isConfigured;

  /// Mengatur konteks produk yang sedang dibuka pengguna (mis. dari Detail Produk).
  /// Jika produk berbeda dari konteks sebelumnya, riwayat chat akan direset.
  void setProductContext(ProductAnalysis? analysis) {
    if (_activeProductContext?.product.barcode == analysis?.product.barcode &&
        _activeProductContext?.product.name == analysis?.product.name) {
      return;
    }
    _activeProductContext = analysis;
    _messages.clear();
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isSending) return;

    _messages.add(
      ChatMessage(
        id: 'usr_${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.user,
        text: text,
      ),
    );
    _isSending = true;
    notifyListeners();

    final collectedRecommendations = <ProductAnalysis>[];

    try {
      String replyText;
      if (_dataSource.isConfigured) {
        final history = _buildGeminiHistory(excludeLast: true);
        final result = await _dataSource.generateReply(
          systemInstruction: _buildSystemInstruction(),
          history: history,
          userMessage: text,
          onToolCall: (name, args) =>
              _handleToolCall(name, args, collectedRecommendations),
        );
        replyText = result.text;
      } else {
        replyText = await _generateLocalReply(text, collectedRecommendations);
      }

      if (!_dataSource.isConfigured) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }

      await _streamAssistantReply(
        replyText,
        recommendedProducts: collectedRecommendations,
      );
    } catch (e) {
      _messages.add(
        ChatMessage(
          id: 'err_${DateTime.now().microsecondsSinceEpoch}',
          role: ChatRole.assistant,
          text:
              'Maaf, terjadi kendala saat memproses pertanyaan Anda: ${e.toString()}',
          isError: true,
        ),
      );
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> _streamAssistantReply(
    String fullText, {
    required List<ProductAnalysis> recommendedProducts,
  }) async {
    final messageId = 'ai_${DateTime.now().microsecondsSinceEpoch}';
    final tokens = RegExp(r'\S+\s*').allMatches(fullText).map((m) => m.group(0)!).toList();

    if (tokens.length <= 1) {
      _messages.add(
        ChatMessage(
          id: messageId,
          role: ChatRole.assistant,
          text: fullText,
          recommendedProducts: recommendedProducts,
        ),
      );
      return;
    }

    _messages.add(
      ChatMessage(
        id: messageId,
        role: ChatRole.assistant,
        text: '',
      ),
    );
    _isSending = false;
    notifyListeners();

    final buffer = StringBuffer();
    for (var i = 0; i < tokens.length; i++) {
      buffer.write(tokens[i]);
      final isLast = i == tokens.length - 1;
      _messages[_messages.length - 1] = ChatMessage(
        id: messageId,
        role: ChatRole.assistant,
        text: buffer.toString(),
        recommendedProducts: isLast ? recommendedProducts : const [],
      );
      notifyListeners();
      if (!isLast) {
        await Future<void>.delayed(const Duration(milliseconds: 28));
      }
    }
  }

  List<Map<String, dynamic>> _buildGeminiHistory({bool excludeLast = false}) {
    final source = excludeLast && _messages.isNotEmpty
        ? _messages.sublist(0, _messages.length - 1)
        : _messages;

    // Ambil maksimal 10 pesan terakhir yang valid & pastikan bergantian user/model
    final filtered = source.where((m) => !m.isError).toList();
    final recent = filtered.length > 10
        ? filtered.sublist(filtered.length - 10)
        : filtered;

    final result = <Map<String, dynamic>>[];
    for (final m in recent) {
      final role = m.role == ChatRole.user ? 'user' : 'model';
      if (result.isEmpty && role == 'model') continue;
      if (result.isNotEmpty && result.last['role'] == role) {
        result.removeLast();
      }
      result.add({
        'role': role,
        'parts': [
          {'text': m.text}
        ],
      });
    }
    // Pesan berikutnya dari user, jadi pastikan history tidak berakhir dengan 'user'
    if (result.isNotEmpty && result.last['role'] == 'user') {
      result.removeLast();
    }
    return result;
  }

  String _buildSystemInstruction() {
    final buffer = StringBuffer()
      ..writeln(
        'Anda adalah NutriAI, asisten edukasi zat aditif pangan dan nutrisi pada aplikasi NutriCheck Indonesia.',
      )
      ..writeln(
        'Tugas utama Anda: (1) menjelaskan zat aditif pada produk makanan/minuman kemasan secara jelas, objektif, dan mudah dipahami konsumen awam; (2) membantu pengguna mencari alternatif produk Indonesia yang lebih sehat.',
      )
      ..writeln(
        'Aturan wajib:\n'
        '- Jika pengguna menanyakan alternatif/rekomendasi produk, WAJIB panggil tool search_healthier_alternatives terlebih dahulu dan HANYA rekomendasikan produk yang dikembalikan oleh tool tersebut. Jangan mengarang merek/nama produk.\n'
        '- Jika pengguna menanyakan zat aditif tertentu, panggil tool lookup_additive terlebih dahulu.\n'
        '- Format jawaban khusus untuk layar HP: JANGAN gunakan tabel Markdown (|...|), heading (#), atau blok kode. Gunakan kalimat singkat, paragraf pendek, dan poin bernomor (1., 2., 3.) atau bullet (•) yang rapi.\n'
        '- Jawab dalam bahasa Indonesia yang ramah dan ringkas, serta ingatkan bahwa informasi bersifat edukatif bukan diagnosis medis.',
      );

    final user = _auth.currentUser;
    if (user != null && user.selectedConditions.isNotEmpty) {
      buffer.writeln(
        'Profil kondisi/preferensi kesehatan pengguna: ${user.selectedConditions.join(', ')}.',
      );
    }

    final adi = _homeData.dailyAdiSummary;
    buffer.writeln(
      'Ringkasan konsumsi ADI pengguna hari ini: ${adi.percentage.toStringAsFixed(0)}%.',
    );

    final ctx = _activeProductContext;
    if (ctx != null) {
      buffer.writeln('\nKonteks produk yang sedang dilihat pengguna:');
      buffer.writeln('- Nama: ${ctx.product.name}');
      if (ctx.product.brand != null && ctx.product.brand!.isNotEmpty) {
        buffer.writeln('- Merek: ${ctx.product.brand}');
      }
      if (ctx.overallRisk != null) {
        buffer.writeln('- Risiko keseluruhan: ${ctx.overallRisk!.label}');
      }
      if (ctx.product.ingredientsText != null &&
          ctx.product.ingredientsText!.isNotEmpty) {
        buffer.writeln('- Komposisi: ${ctx.product.ingredientsText}');
      }
      if (ctx.additives.isNotEmpty) {
        buffer.writeln('- Zat aditif terdeteksi:');
        for (final a in ctx.additives) {
          buffer.writeln(
            '  * ${a.displayName} [${a.riskLevel.label}] - ${a.summary}'
            '${a.adiMgPerKgBw != null ? ' (ADI: ${a.adiMgPerKgBw} mg/kg BB)' : ''}',
          );
        }
      } else if (ctx.hasIngredientData) {
        buffer.writeln('- Tidak terdeteksi zat aditif berisiko di basis data.');
      }
    }

    return buffer.toString();
  }

  Future<Map<String, dynamic>> _handleToolCall(
    String name,
    Map<String, dynamic> args,
    List<ProductAnalysis> collectedRecommendations,
  ) async {
    if (name == 'lookup_additive') {
      final query = (args['query'] as String? ?? '').trim();
      final exact = await _additives.getById(query);
      final results =
          exact != null ? [exact] : await _additives.search(query);

      if (results.isEmpty) {
        return {
          'found': false,
          'message': 'Zat aditif "$query" tidak ditemukan di basis data lokal.',
        };
      }

      return {
        'found': true,
        'additives': results.take(5).map(_additiveToJson).toList(),
      };
    }

    if (name == 'search_healthier_alternatives') {
      final query = (args['query'] as String? ?? '').trim();
      final avoidRaw = (args['avoid_additives'] as List<dynamic>? ?? [])
          .map((e) => e.toString().toLowerCase())
          .toSet();

      final alternatives = await _findHealthierAlternatives(
        query: query,
        avoidKeywords: avoidRaw,
      );

      collectedRecommendations
        ..clear()
        ..addAll(alternatives);

      if (alternatives.isEmpty) {
        return {
          'found': false,
          'message':
              'Belum ditemukan alternatif produk Indonesia untuk "$query" di Open Food Facts.',
        };
      }

      return {
        'found': true,
        'alternatives': alternatives.map((a) {
          return {
            'name': a.product.name,
            'brand': a.product.brand ?? '',
            'barcode': a.product.barcode,
            'nutri_score': a.product.nutriscoreGrade,
            'overall_risk': a.overallRisk?.label ?? 'Belum diketahui',
            'additive_count': a.additives.length,
            'additives': a.additives.map((ad) => ad.displayName).toList(),
          };
        }).toList(),
      };
    }

    return {'error': 'Tool $name tidak dikenal.'};
  }

  Future<List<ProductAnalysis>> _findHealthierAlternatives({
    required String query,
    Set<String> avoidKeywords = const {},
  }) async {
    if (query.isEmpty) return const [];

    try {
      final searchResult = await _products.search(query, pageSize: 15);
      final currentBarcode = _activeProductContext?.product.barcode;
      final analyzed = <ProductAnalysis>[];

      for (final product in searchResult.products) {
        if (currentBarcode != null &&
            currentBarcode.isNotEmpty &&
            product.barcode == currentBarcode) {
          continue;
        }
        final analysis = await _products.analyze(product);
        if (!analysis.hasIngredientData) continue;

        final containsAvoided = avoidKeywords.isNotEmpty &&
            analysis.additives.any((a) {
              final idLower = a.id.toLowerCase();
              final nameLower = a.name.toLowerCase();
              return avoidKeywords.any(
                (kw) => idLower.contains(kw) || nameLower.contains(kw),
              );
            });
        if (containsAvoided) continue;

        analyzed.add(analysis);
        if (analyzed.length >= 8) break;
      }

      analyzed.sort((a, b) {
        final sevA = a.overallRisk?.severity ?? 99;
        final sevB = b.overallRisk?.severity ?? 99;
        if (sevA != sevB) return sevA.compareTo(sevB);
        return a.additives.length.compareTo(b.additives.length);
      });

      return analyzed.take(4).toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _additiveToJson(Additive a) => {
        'id': a.id,
        'e_number': a.eNumber,
        'name': a.name,
        'category': a.category.name,
        'risk_level': a.riskLevel.label,
        'summary': a.summary,
        'health_effects': a.healthEffects,
        'adi_mg_per_kg_bw': a.adiMgPerKgBw,
        'adi_note': a.adiNote,
        'bpom_permitted': a.bpomPermitted,
        'condition_triggers': a.conditionTriggers,
      };

  /// Mode asisten lokal (aktif otomatis bila GEMINI_API_KEY belum dipasang),
  /// tetap menggunakan [AdditiveRepository] dan [ProductRepository].
  Future<String> _generateLocalReply(
    String userText,
    List<ProductAnalysis> collectedRecommendations,
  ) async {
    final lower = userText.toLowerCase();

    // 1. Jika user meminta alternatif produk yang lebih sehat
    final wantsAlternative = lower.contains('alternatif') ||
        lower.contains('pengganti') ||
        lower.contains('lebih sehat') ||
        lower.contains('rekomendasi') ||
        lower.contains('cari produk') ||
        lower.contains('carikan');

    if (wantsAlternative) {
      String query = _extractSearchQuery(userText);
      if (query.isEmpty && _activeProductContext != null) {
        query = _activeProductContext!.product.name.split(' ').first;
      }

      if (query.isNotEmpty) {
        final alternatives = await _findHealthierAlternatives(query: query);
        collectedRecommendations.addAll(alternatives);

        if (alternatives.isNotEmpty) {
          final buf = StringBuffer()
            ..writeln(
              'Berikut beberapa alternatif produk **$query** di Indonesia dengan risiko zat aditif lebih rendah:',
            );
          for (final item in alternatives) {
            final riskLabel = item.overallRisk?.label ?? 'Belum diketahui';
            final brandText = (item.product.brand != null && item.product.brand!.isNotEmpty)
                ? item.product.brand!
                : 'Merek tidak tercatat';
            buf.writeln(
              '• **${item.product.name}** ($brandText) — Risiko: $riskLabel, ${item.additives.length} aditif terdeteksi.',
            );
          }
          buf.write(
            '\nKetuk kartu produk di bawah untuk melihat detail komposisi dan zat aditifnya.',
          );
          return buf.toString();
        }
      }
      return 'Saya belum menemukan alternatif produk yang cocok di database Open Food Facts Indonesia. Coba sebutkan jenis produknya lebih spesifik, misalnya *"carikan alternatif biskuit"* atau *"rekomendasi yogurt lebih sehat"*.';
    }

    // 2. Cek kode E/INS di pesan (mis. E211, E621, INS 102)
    final codeMatch =
        RegExp(r'\b(?:E|INS)[-\s]?(\d{3,4}[a-z]?)\b', caseSensitive: false)
            .firstMatch(userText);
    if (codeMatch != null) {
      final code = 'E${codeMatch.group(1)}';
      final additive = await _additives.getById(code);
      if (additive != null) {
        return _formatAdditiveExplanation(additive);
      }
    }

    // 3. Jika sedang membuka produk dan menanyakan aditif pada produk tersebut
    if (_activeProductContext != null &&
        (lower.contains('produk ini') ||
            lower.contains('aman') ||
            lower.contains('aditif') ||
            lower.contains('kandungan') ||
            lower.contains('bahaya') ||
            lower.contains('risiko'))) {
      return _formatActiveProductSummary(_activeProductContext!);
    }

    // 4. Cari nama zat aditif di basis data lokal
    final cleanedWords = userText
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4)
        .toList();
    for (final word in cleanedWords) {
      final matches = await _additives.search(word);
      if (matches.isNotEmpty) {
        return _formatAdditiveExplanation(matches.first);
      }
    }

    return 'Halo! Saya **NutriAI**, siap membantu Anda memahami zat aditif makanan dan mencari alternatif produk yang lebih sehat.\n\n'
        'Anda bisa menanyakan hal seperti:\n'
        '• *"Jelaskan E211 atau natrium benzoat"*\n'
        '• *"Carikan alternatif saus sambal yang lebih sehat"*\n'
        '• *"Apakah aditif pada produk ini aman?"* (saat membuka Detail Produk)\n\n'
        '_Catatan: Saat ini berjalan dalam mode basis data lokal. Untuk percakapan AI generatif penuh, tambahkan `--dart-define=GEMINI_API_KEY=...` saat menjalankan aplikasi._';
  }

  String _extractSearchQuery(String text) {
    final cleaned = text
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'\b(carikan|cari|tolong|alternatif|pengganti|rekomendasi|produk|yang|lebih|sehat|aman|tanpa|untuk|saya|dong|ya)\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  String _formatAdditiveExplanation(Additive a) {
    final buf = StringBuffer()
      ..writeln('**${a.displayName}** — Risiko: **${a.riskLevel.label}**')
      ..writeln(a.summary);
    if (a.adiMgPerKgBw != null) {
      buf.writeln(
        '• **Batas Harian (ADI):** ${a.adiMgPerKgBw} mg/kg berat badan/hari${a.adiNote != null ? ' (${a.adiNote})' : ''}',
      );
    } else if (a.adiNote != null) {
      buf.writeln('• **Batas Harian (ADI):** ${a.adiNote}');
    }
    buf.writeln(
      '• **Status BPOM:** ${a.bpomPermitted ? 'Diizinkan sebagai BTP sesuai batas' : 'Dilarang / tidak diizinkan'}',
    );
    if (a.healthEffects.isNotEmpty) {
      buf.writeln('• **Catatan Kesehatan:** ${a.healthEffects.join('; ')}');
    }
    return buf.toString().trim();
  }

  String _formatActiveProductSummary(ProductAnalysis analysis) {
    final buf = StringBuffer()
      ..writeln('Ringkasan analisis untuk **${analysis.product.name}**:');

    if (!analysis.hasIngredientData) {
      buf.writeln(
        'Data komposisi produk ini belum lengkap sehingga tingkat risikonya belum dapat dipastikan.',
      );
      return buf.toString().trim();
    }

    buf.writeln(
      '• **Risiko Keseluruhan:** ${analysis.overallRisk?.label ?? 'Belum diketahui'}',
    );

    if (analysis.additives.isEmpty) {
      buf.writeln(
        '• Tidak ada zat aditif berisiko yang terdeteksi dari basis data NutriCheck.',
      );
    } else {
      buf.writeln(
        '• **Zat Aditif Terdeteksi (${analysis.additives.length}):**',
      );
      for (final a in analysis.additives.take(5)) {
        buf.writeln('  - **${a.displayName}** (${a.riskLevel.label}): ${a.summary}');
      }
    }

    buf.write(
      '\nIngin saya carikan alternatif produk sejenis yang lebih sehat? Ketik *"Carikan alternatif lebih sehat"*.',
    );
    return buf.toString().trim();
  }
}
