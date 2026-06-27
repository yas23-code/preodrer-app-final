import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/providers/role_provider.dart';
import '../features/auth/screens/landing_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/auth/widgets/role_gate.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/payment/screens/payment_webview_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/menu/screens/menu_screen.dart';
import '../shared/widgets/customer_bottom_navbar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  // Determine whether auth is still loading (restoring session)
  final isLoading = authState.isLoading;

  // Extract the user only when we have resolved data
  final user = authState.maybeWhen(
    data: (u) => u,
    orElse: () => null,
  );

  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── Public routes (no bottom nav) ──────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          final roleAsync = ref.watch(roleProvider);
          final isVendor = roleAsync.value == AppRole.vendor;
          final isSuperAdmin = roleAsync.value == AppRole.superadmin;

          // Vendors and Super Admins should not see the Customer Bottom Navigation Bar
          if (isVendor || isSuperAdmin) {
            return child;
          }

          final location = state.uri.path;
          final index = switch (location) {
            '/home' => 0,
            '/cart' => 1,
            '/orders' => 2,
            '/profile' => 3,
            _ => 0,
          };
          final title = switch (index) {
            0 => 'Home',
            1 => 'Cart',
            2 => 'Orders',
            3 => 'Profile',
            _ => 'Home',
          };

          return Scaffold(
            body: child,
            bottomNavigationBar: CustomerBottomNavBar(currentIndex: index),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const RoleGate(),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Standalone authenticated routes (no bottom nav) ───────────
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentWebviewScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],

    // ── Global redirect logic ─────────────────────────────────────────
    //
    // LOADING (session being restored):
    //   • Stay on `/` — the landing page serves as a visual splash
    //   • Don't redirect anywhere yet; wait for auth to resolve
    //
    // Unauthenticated (loading complete, no user):
    //   • `/` and `/login` are allowed (public pages)
    //   • Any other path → redirect to `/`
    //
    // Authenticated:
    //   • `/` or `/login` → redirect to `/home`
    //   • Everything else is allowed
    //
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublic = path == '/' || path == '/login';

      // While auth state is still loading (restoring persisted session),
      // keep the user on the landing page. Do NOT redirect to login or
      // home yet — we don't know the answer yet.
      if (isLoading) {
        return isPublic ? null : '/';
      }

      if (user == null) {
        return isPublic ? null : '/';
      }

      // Authenticated user on a public page → send to home
      if (isPublic) {
        return '/home';
      }

      return null;
    },
  );
});
