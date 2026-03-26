import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/menu/screens/menu_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/payment/screens/payment_webview_screen.dart';
import '../features/profile/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.maybeWhen(
    data: (u) => u,
    orElse: () => null,
  );

  return GoRouter(
    initialLocation: user == null ? '/login' : '/home',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => user == null ? '/login' : '/home',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
            bottomNavigationBar: BottomNavigationBar(
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
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  label: 'Menu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart_outlined),
                  label: 'Cart',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const MenuScreen(),
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
    redirect: (context, state) {
      final path = state.uri.path;
      final isLogin = path == '/login';

      if (user == null) {
        return isLogin ? null : '/login';
      }
      if (isLogin) {
        return '/home';
      }
      return null;
    },
  );
});

