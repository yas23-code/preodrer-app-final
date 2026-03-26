import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../../../shared/widgets/food_item_card.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(menuItemsProvider);

    return menuItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load menu: $e')),
      data: (items) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FoodItemCard(
              item: item,
              onAdd: () {
                ref.read(cartControllerProvider.notifier).addItem(item);
              },
            ),
          );
        },
      ),
    );
  }
}

