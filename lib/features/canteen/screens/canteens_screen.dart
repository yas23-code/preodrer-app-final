import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../menu/providers/menu_provider.dart';
import '../providers/canteen_provider.dart';

class CanteensScreen extends ConsumerWidget {
  const CanteensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canteensAsync = ref.watch(canteensProvider);

    return canteensAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Failed to load canteens: $e')),
      data: (canteens) {
        if (canteens.isEmpty) {
          return const Center(
            child: Text('No canteens available right now.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          itemCount: canteens.length,
          itemBuilder: (context, index) {
            final canteen = canteens[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    if (!canteen.isOpen) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This canteen is currently closed.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    ref
                        .read(selectedCanteenIdProvider.notifier)
                        .select(canteen.id);
                    context.push('/menu');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (canteen.imageUrl != null && canteen.imageUrl!.isNotEmpty)
                        Image.network(
                          canteen.imageUrl!,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _PlaceholderImage(),
                        )
                      else
                        const _PlaceholderImage(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              canteen.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    canteen.location ?? 'Campus Canteen',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey.shade700,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: canteen.isOpen
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    canteen.isOpen ? 'OPEN' : 'CLOSED',
                                    style: TextStyle(
                                      color: canteen.isOpen ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.storefront_outlined,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }
}
