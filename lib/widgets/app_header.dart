import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/routes.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.showDefaultActions = true,
    this.showBackButton = false,
    this.onBackTap,
    this.onHelpTap,
    this.onNotificationTap,
    this.customRightWidget,
    this.actions,
    this.leading,
    this.backgroundColor = AppColors.background,
    this.elevation = 0,
  });

  final String? title;
  final bool showDefaultActions;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onNotificationTap;
  final Widget? customRightWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Color backgroundColor;
  final double elevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildContainerAction({
    required IconData icon,
    required String tooltip,
    required String routeName,
    VoidCallback? onTapOverride,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: OpenContainer<bool>(
        tappable: false,
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: const Duration(milliseconds: 320),
        closedElevation: 0,
        openElevation: 0,
        closedColor: Colors.transparent,
        openColor: AppColors.background,
        middleColor: AppColors.primarySurface,
        closedShape: const CircleBorder(),
        openShape: const RoundedRectangleBorder(),
        closedBuilder: (context, openContainer) {
          return SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              tooltip: tooltip,
              icon: Icon(
                icon,
                color: AppColors.textPrimary,
                size: 22,
              ),
              onPressed: onTapOverride ?? openContainer,
            ),
          );
        },
        openBuilder: (context, closeContainer) {
          return AppRoutes.pageForRoute(routeName);
        },
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    if (!showBackButton) return null;

    return IconButton(
      icon: const Icon(
        Icons.arrow_back_rounded,
        color: AppColors.textPrimary,
      ),
      onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
    );
  }

  List<Widget>? _buildActions() {
    if (customRightWidget != null) {
      return [
        customRightWidget!,
        const SizedBox(width: 6),
      ];
    }

    if (actions != null) return actions;

    if (showDefaultActions) {
      return [
        _buildContainerAction(
          icon: Icons.help_outline_rounded,
          tooltip: 'Bantuan',
          routeName: AppRoutes.help,
          onTapOverride: onHelpTap,
        ),
        _buildContainerAction(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifikasi',
          routeName: AppRoutes.notifications,
          onTapOverride: onNotificationTap,
        ),
        const SizedBox(width: 6),
      ];
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: elevation,
      automaticallyImplyLeading: showBackButton,
      leading: _buildLeading(context),
      title: Text(
        title ?? 'NutriCheck',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      actions: _buildActions(),
    );
  }
}