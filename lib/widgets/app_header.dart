import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../screens/help_screen.dart';

/// Reusable Header Component for NutriCheck screens
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final bool showDefaultActions;
  final VoidCallback? onHelpTap;
  final VoidCallback? onNotificationTap;
  final List<Widget>? customActions;
  final Widget? customRightWidget;
  final Color backgroundColor;

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = false,
    this.onBackTap,
    this.showDefaultActions = false,
    this.onHelpTap,
    this.onNotificationTap,
    this.customActions,
    this.customRightWidget,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: onBackTap ?? () => Navigator.maybePop(context),
            )
          : null,
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : Text(
                  'nutricheck',
                  style: GoogleFonts.comfortaa(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                )),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (customRightWidget != null) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: customRightWidget!,
        ),
      ];
    }

    if (customActions != null) {
      return customActions!;
    }

    if (showDefaultActions) {
      return [
        IconButton(
          icon: SvgPicture.asset(
            'assets/bantuan.svg',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(
              AppColors.textSecondary,
              BlendMode.srcIn,
            ),
          ),
          onPressed: onHelpTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
          tooltip: 'Bantuan',
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
          onPressed: onNotificationTap ?? () {},
          tooltip: 'Notifikasi',
        ),
        const SizedBox(width: 4),
      ];
    }

    return [];
  }
}
