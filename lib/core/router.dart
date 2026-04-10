import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/landing_screen.dart';
import '../features/cart/models/cart_model.dart';
import '../features/cart/providers/cart_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/auth/widgets/role_gate.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/payment/screens/payment_webview_screen.dart';
import '../features/profile/screens/profile_screen.dart';

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

      // ── Authenticated shell (with bottom nav) ─────────────────────
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          final index = switch (location) {
            '/home' => 0,
            '/cart' => 1,
            '/orders' => 2,
            '/profile' => 3,
            _ => 0,
          };
          final title = switch (index) {
            0 => 'Menu',
            1 => 'Cart',
            2 => 'Orders',
            3 => 'Profile',
            _ => 'Menu',
          };

          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: child,
            bottomNavigationBar: Consumer(
              builder: (context, ref, _) {
                final cartState = ref.watch(cartControllerProvider).asData?.value;
                final itemCount = cartState?.itemCount ?? 0;

                return BottomNavigationBar(
                  currentIndex: index,
                  type: BottomNavigationBarType.fixed,
                  onTap: (i) {
                    final target = switch (i) {
                      0 => '/home',
                      1 => '/cart',
                      2 => '/orders',
                      3 => '/profile',
                      _ => '/home',
                    };
                    context.go(target);
                  },
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.restaurant_menu_outlined),
                      label: 'Menu',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        isLabelVisible: itemCount > 0,
                        label: Text('$itemCount'),
                        child: const Icon(Icons.shopping_cart_outlined),
                      ),
                      label: 'Cart',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_outlined),
                      label: 'Orders',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Profile',
                    ),
                  ],
                );
              },
            ),
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
        path: '/order/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentWebviewScreen(),
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
