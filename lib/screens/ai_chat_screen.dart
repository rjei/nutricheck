import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/risk_level_style.dart';
import '../data/models/product_analysis.dart';
import '../models/chat_message.dart';
import '../services/ai_chat_service.dart';
import 'product_detail_screen.dart';

/// Halaman percakapan NutriAI untuk edukasi zat aditif dan pencarian
/// alternatif produk yang lebih sehat.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    this.initialProductContext,
    this.chatService,
  });

  final ProductAnalysis? initialProductContext;
  final AiChatService? chatService;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  AiChatService get _service => widget.chatService ?? AiChatService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.initialProductContext != null) {
      _service.setProductContext(widget.initialProductContext);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _controller.clear();
    }

    await _service.sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NutriAI Asisten',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Info Zat Aditif & Alternatif Sehat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _service.clearChat(),
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textSecondary),
            tooltip: 'Bersihkan percakapan',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final messages = _service.messages;
          final productContext = _service.activeProductContext;

          return Column(
            children: [
              if (productContext != null) _buildContextBanner(productContext),
              _buildDisclaimerBanner(),
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState(productContext)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: messages.length + (_service.isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return _buildTypingBubble();
                          }
                          return _buildMessageBubble(messages[index]);
                        },
                      ),
              ),
              _buildInputBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContextBanner(ProductAnalysis analysis) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Konteks produk: ${analysis.product.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _service.setProductContext(null),
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.badgeBackground,
      child: Text(
        'Informasi AI bersifat edukatif berdasarkan database BPOM/Open Food Facts dan bukan pengganti saran medis.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ProductAnalysis? productContext) {
    final prompts = productContext != null
        ? [
            'Apakah zat aditif pada produk ini aman?',
            'Carikan alternatif ${productContext.product.name.split(' ').first} yang lebih sehat',
            'Aditif mana yang perlu diwaspadai?',
          ]
        : [
            'Jelaskan E211 (Natrium Benzoat) dan batas amannya',
            'Carikan alternatif biskuit yang lebih sehat',
            'Carikan alternatif saus sambal rendah aditif',
            'Apa risiko pemanis buatan aspartam (E951)?',
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Tanya Seputar Zat Aditif & Produk Sehat',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Saya dapat membantu menjelaskan kandungan aditif pada produk kemasan serta mencarikan alternatif produk Indonesia yang lebih aman.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pertanyaan cepat:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts.map((prompt) {
              return ActionChip(
                label: Text(
                  prompt,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.primaryLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => _send(prompt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primary
                  : (message.isError ? const Color(0xFFFEE2E2) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: message.isError
                          ? const Color(0xFFFCA5A5)
                          : AppColors.border,
                    ),
            ),
            child: _buildFormattedText(
              message.text,
              GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                height: 1.5,
                color: isUser
                    ? Colors.white
                    : (message.isError
                        ? const Color(0xFF991B1B)
                        : AppColors.textPrimary),
              ),
            ),
          ),
          if (message.recommendedProducts.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...message.recommendedProducts.map(_buildProductRecommendationCard),
          ],
        ],
      ),
    );
  }

  /// Merender teks dengan dukungan **bold**, *italic*, dan bullet rapi
  /// tanpa menampilkan simbol Markdown mentah di layar HP.
  Widget _buildFormattedText(String rawText, TextStyle baseStyle) {
    final normalized = rawText
        .split('\n')
        .map((line) {
          final trimmed = line.trimLeft();
          // Hilangkan garis pemisah tabel Markdown jika masih muncul
          if (RegExp(r'^\|[\s\-:|]+\|$').hasMatch(trimmed)) {
            return null;
          }
          var out = line.replaceFirst(RegExp(r'^#{1,4}\s+'), '');
          out = out.replaceFirst(RegExp(r'^\s*[-*]\s+'), '• ');
          return out;
        })
        .whereType<String>()
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|_(?!_)(.+?)_');
    int lastEnd = 0;

    for (final match in pattern.allMatches(normalized)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: normalized.substring(lastEnd, match.start)));
      }
      final boldText = match.group(1);
      final italicText = match.group(2) ?? match.group(3);
      if (boldText != null) {
        spans.add(
          TextSpan(
            text: boldText,
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (italicText != null) {
        spans.add(
          TextSpan(
            text: italicText,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }
      lastEnd = match.end;
    }

    if (lastEnd < normalized.length) {
      spans.add(TextSpan(text: normalized.substring(lastEnd)));
    }

    return SelectableText.rich(
      TextSpan(style: baseStyle, children: spans),
    );
  }

  Widget _buildProductRecommendationCard(ProductAnalysis analysis) {
    final risk = analysis.overallRisk;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.86,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: analysis.product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: risk?.backgroundColor ?? AppColors.badgeBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  risk?.icon ?? Icons.help_outline_rounded,
                  color: risk?.color ?? AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${(analysis.product.brand != null && analysis.product.brand!.isNotEmpty) ? '${analysis.product.brand} • ' : ''}'
                      '${risk?.label ?? 'Belum diketahui'} • ${analysis.additives.length} aditif',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'NutriAI sedang menganalisis...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _send(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tanya zat aditif atau cari alternatif sehat...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.searchBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: _service,
                builder: (context, _) {
                  return CircleAvatar(
                    radius: 22,
                    backgroundColor: _service.isSending
                        ? AppColors.textMuted
                        : AppColors.primary,
                    child: IconButton(
                      onPressed: _service.isSending ? null : () => _send(),
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Kirim pertanyaan',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
