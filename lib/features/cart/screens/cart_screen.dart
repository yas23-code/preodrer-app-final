import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/cart_model.dart';
import '../providers/cart_controller.dart';
import '../../../shared/utils/formatters.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[UI_WIRING] cart_screen.dart build() called');
    final cartAsync = ref.watch(cartControllerProvider);
    
    // DB Diagnosis logs
    if (cartAsync.hasValue) {
      final cart = cartAsync.value!;
      debugPrint('[DB_DIAGNOSIS] cart_screen.dart: cart.itemCount=${cart.itemCount}, keys=${cart.lines.keys}');
      for (final line in cart.lines.values) {
        debugPrint('[DB_DIAGNOSIS] cart_screen.dart: rendering item="${line.item.name}", quantity=${line.quantity}');
      }
    } else {
      debugPrint('[DB_DIAGNOSIS] cart_screen.dart: cartAsync has no value yet');
    }

    return cartAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load cart: $e')),
      data: (cart) => Column(
        children: [
          Expanded(
            child: cart.lines.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final line = cart.lines.values.elementAt(index);
                          final lineTotal = formatCurrency(line.item.price * line.quantity);
                          return ListTile(
                            title: Text(line.item.name),
                            subtitle: Text(
                              '${formatCurrency(line.item.price)} x ${line.quantity} = $lineTotal',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => ref
                                      .read(cartControllerProvider.notifier)
                                      .decrementItem(line.item),
                                ),
                                Text('${line.quantity}'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => ref
                                      .read(cartControllerProvider.notifier)
                                      .addItem(line.item),
                                ),
                              ],
                            ),
                          );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Total: ${formatCurrency(cart.totalAmount)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: cart.lines.isEmpty
                        ? null
                        : () {
                            context.go('/payment');
                          },
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
