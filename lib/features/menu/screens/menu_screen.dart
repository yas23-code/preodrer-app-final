import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/providers/cart_controller.dart';
import '../providers/menu_provider.dart';
import '../../../shared/widgets/food_item_card.dart';
import '../../../shared/widgets/customer_bottom_navbar.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(menuItemsProvider);

    return menuItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load menu: $e')),
      data: (items) => Scaffold(
        appBar: AppBar(
          title: const Text('Menu'),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FoodItemCard(
              item: item,
              onAdd: () {
                debugPrint('[UI_WIRING] onAdd callback triggered in MenuScreen for ${item.name}');
                try {
                  final notifier = ref.read(cartControllerProvider.notifier);
                  debugPrint('[UI_WIRING] Successfully read cartControllerProvider.notifier');
                  notifier.addItem(item);
                  debugPrint('[UI_WIRING] successfully called addItem(item)');
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} added to cart'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e, st) {
                  debugPrint('[UI_WIRING] Error calling addItem: $e\n$st');
                }
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 0),
      ),
    );
  }
}

