import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/providers/cart_controller.dart';

class CustomerBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const CustomerBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider).asData?.value;
    final itemCount = cartState?.itemCount ?? 0;

    // Design Tokens
    const primaryYellow = Color(0xFFFFC107);
    const accentRed = Color(0xFFE53935);
    const textPrimary = Color(0xFF222222);
    const textSecondary = Color(0xFF666666);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: accentRed,
          unselectedItemColor: textSecondary,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          onTap: (i) {
            if (i == currentIndex) return;
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
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: accentRed),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: itemCount > 0,
                label: Text('$itemCount'),
                backgroundColor: accentRed,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: itemCount > 0,
                label: Text('$itemCount'),
                backgroundColor: accentRed,
                child: const Icon(Icons.shopping_cart, color: accentRed),
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long, color: accentRed),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: accentRed),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
