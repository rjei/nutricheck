import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/product.dart';
import '../data/models/product_analysis.dart';
import '../screens/activity_screen.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/health_survey_screen.dart';
import '../screens/help_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/search_screen.dart';
import '../services/auth_service.dart';
import 'app_colors.dart';

typedef Routes = AppRoutes;

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String search = '/search';
  static const String scan = '/scan';
  static const String activity = '/activity';
  static const String help = '/help';
  static const String notifications = '/notifications';
  static const String healthSurvey = '/health-survey';
  static const String aiChat = '/ai-chat';
  static const String productDetail = '/product-detail';

  static const Duration tabTransitionDuration = Duration(milliseconds: 300);

  static final GoRouter router = GoRouter(
    initialLocation: AuthService().isLoggedIn ? home : login,
    routes: [
      GoRoute(
        path: home,
        name: home,
        pageBuilder: (context, state) => _fadeThroughPage(
          state: state,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: login,
        name: login,
        pageBuilder: (context, state) => _fadeThroughPage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: search,
        name: search,
        pageBuilder: (context, state) => _sharedAxisPage(
          state: state,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: scan,
        name: scan,
        pageBuilder: (context, state) => _sharedAxisPage(
          state: state,
          type: SharedAxisTransitionType.vertical,
          child: const ScanScreen(),
        ),
      ),
      GoRoute(
        path: activity,
        name: activity,
        pageBuilder: (context, state) => _sharedAxisPage(
          state: state,
          child: const ActivityScreen(),
        ),
      ),
      GoRoute(
        path: help,
        name: help,
        pageBuilder: (context, state) => _sharedAxisPage(
          state: state,
          child: const HelpScreen(),
        ),
      ),
      GoRoute(
        path: notifications,
        name: notifications,
        pageBuilder: (context, state) => _sharedAxisPage(
          state: state,
          child: const NotificationScreen(),
        ),
      ),
      GoRoute(
        path: healthSurvey,
        name: healthSurvey,
        pageBuilder: (context, state) => _sharedAxisPage(
          state: state,
          type: SharedAxisTransitionType.vertical,
          child: const HealthSurveyScreen(),
        ),
      ),
      GoRoute(
        path: aiChat,
        name: aiChat,
        pageBuilder: (context, state) => _sharedAxisPage(
          state: state,
          type: SharedAxisTransitionType.scaled,
          child: AiChatScreen(
            initialProductContext: state.extra as ProductAnalysis?,
          ),
        ),
      ),
      GoRoute(
        path: productDetail,
        name: productDetail,
        pageBuilder: (context, state) => _sharedAxisPage(
          state: state,
          child: ProductDetailScreen(
            product: state.extra as Product,
          ),
        ),
      ),
    ],
  );

  static CustomTransitionPage<void> _sharedAxisPage({
    required GoRouterState state,
    required Widget child,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: type,
          fillColor: AppColors.background,
          child: child,
        );
      },
    );
  }

  static CustomTransitionPage<void> _fadeThroughPage({
    required GoRouterState state,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: AppColors.background,
          child: child,
        );
      },
    );
  }

  static Widget pageForRoute(
      String routeName, {
        Object? arguments,
      }) {
    switch (routeName) {
      case home:
        return const HomeScreen();
      case login:
        return const LoginScreen();
      case search:
        return const SearchScreen();
      case scan:
        return const ScanScreen();
      case activity:
        return const ActivityScreen();
      case help:
        return const HelpScreen();
      case notifications:
        return const NotificationScreen();
      case healthSurvey:
        return const HealthSurveyScreen();
      case aiChat:
        return AiChatScreen(
          initialProductContext: arguments as ProductAnalysis?,
        );
      case productDetail:
        return ProductDetailScreen(
          product: arguments as Product,
        );
      default:
        return const HomeScreen();
    }
  }

  static Widget buildTabTransition({
    required Widget child,
    required Animation<double> primaryAnimation,
    required Animation<double> secondaryAnimation,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) {
    return SharedAxisTransition(
      animation: primaryAnimation,
      secondaryAnimation: secondaryAnimation,
      transitionType: type,
      fillColor: AppColors.background,
      child: child,
    );
  }

  static Future<T?> pushProductDetail<T>(
      BuildContext context, {
        required Product product,
      }) {
    return context.push<T>(productDetail, extra: product);
  }

  static Future<T?> pushAiChat<T>(
      BuildContext context, {
        ProductAnalysis? initialProductContext,
      }) {
    return context.push<T>(aiChat, extra: initialProductContext);
  }

  static Future<T?> pushHelp<T>(BuildContext context) {
    return context.push<T>(help);
  }

  static Future<T?> pushNotifications<T>(BuildContext context) {
    return context.push<T>(notifications);
  }

  static Future<T?> pushHealthSurvey<T>(BuildContext context) {
    return context.push<T>(healthSurvey);
  }

  static void pushLogin(BuildContext context) {
    context.go(login);
  }
}