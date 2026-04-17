import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_controller.dart';
import '../../../shared/utils/formatters.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isOrdering = false;

  @override
  Widget build(BuildContext context) {
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
                    onPressed: (cart.lines.isEmpty || _isOrdering)
                        ? null
                        : () async {
                            setState(() {
                              _isOrdering = true;
                            });
                            try {
                              await ref.read(cartControllerProvider.notifier).placeOrder();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Order placed successfully!')),
                                );
                                context.go('/orders');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to place order: $e')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isOrdering = false;
                                });
                              }
                            }
                          },
                    child: _isOrdering 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          )
                        : const Text('Order'),
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
