import 'package:flutter/material.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/auth/presentation/screens/login_screen.dart';
import 'package:food_pos/features/auth/presentation/screens/signup_screen.dart';
import 'package:food_pos/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:food_pos/features/home/presentation/screens/home_screen.dart';
import 'package:food_pos/features/products/presentation/screens/add_edit_product_screen.dart';
import 'package:food_pos/features/receipt/presentation/screens/receipt_screen.dart';
import 'package:food_pos/features/splash/presentation/screens/splash_screen.dart';
import 'package:food_pos/routers/app_routes.dart';
import 'package:food_pos/routers/global_navigator.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignupScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      pageBuilder: (context, state) {
        final initialTab = state.extra as int? ?? 0;
        return CustomTransitionPage(
          key: state.pageKey,
          child: HomeScreen(initialTabIndex: initialTab),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.checkout,
      name: 'checkout',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final items = extra?['items'] as List<CartItem>?;
        final subtotal = extra?['subtotal'] as double?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: CheckoutScreen(
            items: items,
            subtotal: subtotal,
          ),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.receipt,
      name: 'receipt',
      pageBuilder: (context, state) {
        final tx = state.extra as PosTransaction?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ReceiptScreen(transaction: tx),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.addEditProduct,
      name: 'add-edit-product',
      pageBuilder: (context, state) {
        final product = state.extra as PosProduct?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: AddEditProductScreen(productToEdit: product),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      },
    ),
  ],
);
