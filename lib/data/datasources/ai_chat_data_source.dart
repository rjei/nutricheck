import 'dart:convert';
import 'package:http/http.dart' as http;

class AiChatException implements Exception {
  AiChatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Hasil eksekusi satu putaran chat AI.
class AiGenerationResult {
  const AiGenerationResult({required this.text});
  final String text;
}

/// Callback untuk mengeksekusi tool/function yang dipanggil oleh LLM.
typedef AiToolExecutor = Future<Map<String, dynamic>> Function(
  String name,
  Map<String, dynamic> args,
);

/// Abstraksi sumber data AI agar mudah diganti (Gemini, Backend Proxy, atau Mock).
abstract class AiChatDataSource {
  bool get isConfigured;

  Future<AiGenerationResult> generateReply({
    required String systemInstruction,
    required List<Map<String, dynamic>> history,
    required String userMessage,
    required AiToolExecutor onToolCall,
  });
}

/// Implementasi Gemini REST API dengan dukungan Function Calling.
///
/// Jalankan dengan `--dart-define=GEMINI_API_KEY=...` untuk mengaktifkan.
class GeminiAiChatDataSource implements AiChatDataSource {
  GeminiAiChatDataSource({
    http.Client? client,
    String? apiKey,
    this.model = 'gemini-2.5-flash',
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY');

  final http.Client _client;
  final String _apiKey;
  final String model;

  @override
  bool get isConfigured => _apiKey.trim().isNotEmpty;

  static final List<Map<String, dynamic>> _toolDeclarations = [
    {
      'functionDeclarations': [
        {
          'name': 'lookup_additive',
          'description':
              'Mencari informasi detail zat aditif makanan (kode E/INS, nama, tingkat risiko, batas ADI, status BPOM, efek kesehatan, dan pemicu kondisi kesehatan) dari basis data NutriCheck.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'query': {
                'type': 'STRING',
                'description':
                    'Kode E/INS (mis. E211, E621) atau nama zat aditif (mis. natrium benzoat, aspartam).',
              },
            },
            'required': ['query'],
          },
        },
        {
          'name': 'search_healthier_alternatives',
          'description':
              'Mencari produk makanan/minuman kemasan yang beredar di Indonesia dari Open Food Facts lalu menganalisis dan mengurutkan alternatif yang lebih sehat (risiko aditif lebih rendah / lebih sedikit zat aditif).',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'query': {
                'type': 'STRING',
                'description':
                    'Kata kunci jenis produk dalam bahasa Indonesia atau umum (mis. biskuit, yogurt, saus sambal, mie instan, teh kemasan).',
              },
              'avoid_additives': {
                'type': 'ARRAY',
                'items': {'type': 'STRING'},
                'description':
                    'Daftar kode atau nama aditif yang ingin dihindari (opsional).',
              },
            },
            'required': ['query'],
          },
        },
      ],
    },
  ];

  @override
  Future<AiGenerationResult> generateReply({
    required String systemInstruction,
    required List<Map<String, dynamic>> history,
    required String userMessage,
    required AiToolExecutor onToolCall,
  }) async {
    if (!isConfigured) {
      throw AiChatException('GEMINI_API_KEY belum dikonfigurasi.');
    }

    final contents = <Map<String, dynamic>>[
      ...history,
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      },
    ];

    final trimmedKey = _apiKey.trim();
    final isVertexExpress = trimmedKey.startsWith('AQ.');
    final uri = Uri.parse(
      isVertexExpress
          ? 'https://aiplatform.googleapis.com/v1/publishers/google/models/$model:generateContent?key=$trimmedKey'
          : 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$trimmedKey',
    );

    // Maksimal 4 putaran function calling agar tidak infinite loop
    for (int step = 0; step < 4; step++) {
      final body = jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ],
        },
        'contents': contents,
        'tools': _toolDeclarations,
        'generationConfig': {
          'temperature': 0.4,
        },
      });

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String detail = '';
        try {
          final errJson = jsonDecode(response.body) as Map<String, dynamic>;
          final errObj = errJson['error'] as Map<String, dynamic>?;
          detail = (errObj?['message'] as String? ?? '').trim();
        } catch (_) {}
        throw AiChatException(
          detail.isNotEmpty
              ? 'Gagal menghubungi layanan AI (HTTP ${response.statusCode}): $detail'
              : 'Gagal menghubungi layanan AI (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw AiChatException('AI tidak memberikan respons.');
      }

      final content =
          candidates.first['content'] as Map<String, dynamic>? ?? {};
      final parts = (content['parts'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      final functionCalls =
          parts.where((p) => p.containsKey('functionCall')).toList();

      if (functionCalls.isEmpty) {
        final text = parts
            .map((p) => p['text'] as String?)
            .whereType<String>()
            .join('\n')
            .trim();
        if (text.isEmpty) {
          throw AiChatException('Respons AI kosong.');
        }
        return AiGenerationResult(text: text);
      }

      // Simpan respons model yang berisi functionCall ke riwayat putaran
      contents.add({
        'role': 'model',
        'parts': parts,
      });

      final functionResponses = <Map<String, dynamic>>[];
      for (final callPart in functionCalls) {
        final call = callPart['functionCall'] as Map<String, dynamic>;
        final name = call['name'] as String? ?? '';
        final args = (call['args'] as Map<String, dynamic>?) ?? const {};
        final result = await onToolCall(name, args);
        functionResponses.add({
          'functionResponse': {
            'name': name,
            'response': result,
          },
        });
      }

      contents.add({
        'role': 'user',
        'parts': functionResponses,
      });
    }

    throw AiChatException('Terlalu banyak langkah pencarian AI.');
  }
}


/// Implementasi Groq API (OpenAI-compatible) dengan dukungan Function Calling.
///
/// Gratis tanpa kartu kredit melalui console.groq.com.
/// Jalankan dengan `--dart-define=GROQ_API_KEY=gsk_...` untuk mengaktifkan.
class GroqAiChatDataSource implements AiChatDataSource {
  GroqAiChatDataSource({
    http.Client? client,
    String? apiKey,
    this.model = 'llama-3.1-8b-instant',
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? const String.fromEnvironment('GROQ_API_KEY');

  final http.Client _client;
  final String _apiKey;
  final String model;

  static const List<String> _fallbackModels = [
    'llama-3.1-8b-instant',
    'openai/gpt-oss-20b',
    'openai/gpt-oss-120b',
  ];

  @override
  bool get isConfigured => _apiKey.trim().isNotEmpty;

  static final List<Map<String, dynamic>> _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'lookup_additive',
        'description':
            'Mencari informasi detail zat aditif makanan (kode E/INS, nama, tingkat risiko, batas ADI, status BPOM, efek kesehatan, dan pemicu kondisi kesehatan) dari basis data NutriCheck.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description':
                  'Kode E/INS (mis. E211, E621) atau nama zat aditif (mis. natrium benzoat, aspartam).',
            },
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'search_healthier_alternatives',
        'description':
            'Mencari produk makanan/minuman kemasan yang beredar di Indonesia dari Open Food Facts lalu menganalisis dan mengurutkan alternatif yang lebih sehat.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description':
                  'Kata kunci jenis produk (mis. biskuit, yogurt, saus sambal, kopi susu, mie instan).',
            },
            'avoid_additives': {
              'type': 'array',
              'items': {'type': 'string'},
              'description':
                  'Daftar kode atau nama aditif yang ingin dihindari (opsional).',
            },
          },
          'required': ['query'],
        },
      },
    },
  ];

  @override
  Future<AiGenerationResult> generateReply({
    required String systemInstruction,
    required List<Map<String, dynamic>> history,
    required String userMessage,
    required AiToolExecutor onToolCall,
  }) async {
    if (!isConfigured) {
      throw AiChatException('GROQ_API_KEY belum dikonfigurasi.');
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemInstruction},
      ...history.map((item) {
        final rawRole = item['role'] as String? ?? 'user';
        final role = rawRole == 'model' ? 'assistant' : rawRole;
        final parts = item['parts'] as List<dynamic>? ?? const [];
        final text = parts.isNotEmpty
            ? (parts.first as Map<String, dynamic>)['text'] as String? ?? ''
            : '';
        return {'role': role, 'content': text};
      }),
      {'role': 'user', 'content': userMessage},
    ];

    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final candidateModels = [
      model,
      ..._fallbackModels.where((m) => m != model),
    ];
    int modelIndex = 0;

    for (int step = 0; step < 6; step++) {
      final activeModel = candidateModels[modelIndex];
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_apiKey.trim()}',
            },
            body: jsonEncode({
              'model': activeModel,
              'messages': messages,
              'tools': _tools,
              'tool_choice': 'auto',
              'temperature': 0.4,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 404 &&
          modelIndex + 1 < candidateModels.length) {
        modelIndex++;
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String detail = '';
        try {
          final errJson = jsonDecode(response.body) as Map<String, dynamic>;
          final errObj = errJson['error'] as Map<String, dynamic>?;
          detail = (errObj?['message'] as String? ?? '').trim();
        } catch (_) {}
        throw AiChatException(
          detail.isNotEmpty
              ? 'Gagal menghubungi layanan AI (HTTP ${response.statusCode}): $detail'
              : 'Gagal menghubungi layanan AI (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw AiChatException('AI tidak memberikan respons.');
      }

      final message =
          (choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>? ??
          {};
      final toolCalls =
          (message['tool_calls'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();

      if (toolCalls.isEmpty) {
        final text = (message['content'] as String? ?? '').trim();
        if (text.isEmpty) {
          throw AiChatException('Respons AI kosong.');
        }
        return AiGenerationResult(text: text);
      }

      messages.add(message);

      for (final call in toolCalls) {
        final fn = call['function'] as Map<String, dynamic>? ?? const {};
        final name = fn['name'] as String? ?? '';
        final rawArgs = fn['arguments'] as String? ?? '{}';
        Map<String, dynamic> args = const {};
        try {
          args = jsonDecode(rawArgs) as Map<String, dynamic>;
        } catch (_) {}

        final result = await onToolCall(name, args);
        messages.add({
          'role': 'tool',
          'tool_call_id': call['id'] ?? '',
          'content': jsonEncode(result),
        });
      }
    }

    throw AiChatException('Terlalu banyak langkah pencarian AI.');
  }
}
