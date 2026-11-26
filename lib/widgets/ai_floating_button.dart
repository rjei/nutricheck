import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/routes.dart';
import '../data/models/product_analysis.dart';
import '../services/ai_chat_service.dart';

class AiFloatingButton extends StatelessWidget {
  const AiFloatingButton({
    super.key,
    this.initialProductContext,
    this.productAnalysis,
    this.chatService,
    this.label = 'Tanya AI',
  });

  final ProductAnalysis? initialProductContext;
  final ProductAnalysis? productAnalysis;
  final AiChatService? chatService;
  final String label;

  @override
  Widget build(BuildContext context) {
    final resolvedContext = initialProductContext ?? productAnalysis;

    return OpenContainer<bool>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 320),
      closedElevation: 4,
      openElevation: 0,
      closedColor: AppColors.primary,
      openColor: AppColors.background,
      middleColor: AppColors.primarySurface,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      openShape: const RoundedRectangleBorder(),
      closedBuilder: (context, openContainer) {
        return Material(
          color: AppColors.primary,
          child: InkWell(
            onTap: openContainer,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  if (label.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      openBuilder: (context, closeContainer) {
        return AppRoutes.pageForRoute(
          AppRoutes.aiChat,
          arguments: resolvedContext,
        );
      },
    );
  }
}