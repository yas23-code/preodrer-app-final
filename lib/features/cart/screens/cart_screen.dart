import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../../../shared/utils/formatters.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);

    return Column(
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
                    return ListTile(
                      title: Text(line.item.name),
                      subtitle: Text(
                        '${formatCurrency(line.item.price)} x ${line.quantity}',
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
    );
  }
}

