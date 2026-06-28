import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/providers/role_provider.dart';
import '../features/auth/screens/landing_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/registration_status_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/auth/widgets/role_gate.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/payment/screens/payment_webview_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/menu/screens/menu_screen.dart';
import '../shared/widgets/customer_bottom_navbar.dart';

import 'package:flutter/foundation.dart';

/// A notifier that triggers GoRouter redirect execution when any relevant auth or role providers change,
/// without destroying and recreating the GoRouter instance itself.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (prev, next) {
      debugPrint('[ROUTER_NOTIFY] authControllerProvider: $prev -> $next');
      _notify();
    });
    ref.listen(roleProvider, (prev, next) {
      debugPrint('[ROUTER_NOTIFY] roleProvider: $prev -> $next');
      _notify();
    });
    ref.listen(vendorStatusProvider, (prev, next) {
      debugPrint('[ROUTER_NOTIFY] vendorStatusProvider: $prev -> $next');
      _notify();
    });
  }

  void _notify() {
    // Defer notification to the next microtask to avoid interrupting GoRouter's
    // redirect evaluation synchronously, which causes infinite loop resets to '/'.
    Future.microtask(() {
      notifyListeners();
    });
  }
}

/// A widget to load and render the registration status screen, wrapping the watch call so it doesn't rebuild the GoRouter instance.
class ShopRegistrationStatusScreenLoader extends ConsumerWidget {
  const ShopRegistrationStatusScreenLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regAsync = ref.watch(myRegistrationProvider);
    return regAsync.when(
      data: (reg) {
        final status = reg?['status'] as String? ?? 'pending';
        final reason = reg?['rejection_reason'] as String?;
        return ShopRegistrationStatusScreen(
          status: status,
          rejectionReason: reason,
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const ShopRegistrationStatusScreen(
        status: 'pending',
      ),
    );
  }
}

/// A wrapper screen for ShellRoute to handle role-based navigation bar rendering securely.
class ShellScreen extends ConsumerWidget {
  final Widget child;
  final GoRouterState state;

  const ShellScreen({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      body: child,
      bottomNavigationBar: CustomerBottomNavBar(currentIndex: index),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  debugPrint('[ROUTER_PROVIDER] Building GoRouter instance!');
  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
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

      // ── Vendor Pending Approval route ──────────────────────────────
      GoRoute(
        path: '/vendor-pending',
        builder: (context, state) => const ShopRegistrationStatusScreenLoader(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return ShellScreen(state: state, child: child);
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
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['category'];
          return MenuScreen(initialCategoryId: categoryId);
        },
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
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublic = path == '/' || path == '/login';
      final isVendorPending = path == '/vendor-pending';

      final authState = ref.read(authControllerProvider);
      final isLoading = authState.isLoading;
      final user = authState.maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );

      debugPrint('[ROUTER_REDIRECT] Path: $path, isLoading: $isLoading, user: ${user?.id}');

      // While auth state is still loading (restoring persisted session),
      // keep the user on the landing page.
      if (isLoading) {
        debugPrint('[ROUTER_REDIRECT] Auth is loading, staying on landing/public');
        return isPublic ? null : '/';
      }

      if (user == null) {
        // Unauthenticated user trying to access vendor-pending should go to login
        if (isVendorPending) {
          debugPrint('[ROUTER_REDIRECT] Unauthenticated on /vendor-pending, redirecting to /');
          return '/';
        }
        debugPrint('[ROUTER_REDIRECT] Unauthenticated, redirecting to public or /');
        return isPublic ? null : '/';
      }

      // ── Role + vendor-status based redirect ───────────────────────
      final roleAsync = ref.read(roleProvider);
      final vendorStatusAsync = ref.read(vendorStatusProvider);

      final role = roleAsync.value;
      final vendorStatus = vendorStatusAsync.value;

      debugPrint('[ROUTER_REDIRECT] Authenticated. Role: $role (loading: ${roleAsync.isLoading}), VendorStatus: $vendorStatus (loading: ${vendorStatusAsync.isLoading})');

      // While role or vendor status is still loading, keep user on public or pending page
      // to avoid flashing the wrong dashboard or triggering redirect loops
      if (roleAsync.isLoading || vendorStatusAsync.isLoading) {
        debugPrint('[ROUTER_REDIRECT] Role/Status is loading, allowing public or pending');
        if (isPublic || isVendorPending) return null;
        return '/';
      }

      // Vendor with a non-approved registration → force to pending page
      if (role == AppRole.vendor && vendorStatus != 'approved' && vendorStatus != null) {
        debugPrint('[ROUTER_REDIRECT] Vendor not approved, redirecting to /vendor-pending');
        return isVendorPending ? null : '/vendor-pending';
      }

      // Customer who has a pending/rejected canteen registration → pending page
      if (role == AppRole.customer && (vendorStatus == 'pending' || vendorStatus == 'rejected')) {
        debugPrint('[ROUTER_REDIRECT] Customer with pending/rejected registration, redirecting to /vendor-pending');
        return isVendorPending ? null : '/vendor-pending';
      }

      // Approved vendor or any other authenticated user on the pending page → send to home
      if (isVendorPending) {
        debugPrint('[ROUTER_REDIRECT] Approved/Valid user on /vendor-pending, redirecting to /home');
        return '/home';
      }

      // Authenticated user on a public page → send to home
      if (isPublic) {
        debugPrint('[ROUTER_REDIRECT] Authenticated user on public page, redirecting to /home');
        return '/home';
      }

      debugPrint('[ROUTER_REDIRECT] Allowing path: $path');
      return null;
    },
  );
});
