import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/supabase_client.dart';
import '../../features/menu/models/menu_item.dart';
import '../utils/formatters.dart';

class FoodItemCard extends ConsumerWidget {
  final MenuItem item;
  final VoidCallback? onAdd;

  const FoodItemCard({
    super.key,
    required this.item,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.watch(supabaseClientProvider);

    final imageUrl = item.imagePath == null
        ? null
        : supabase.storage.from(kFoodImagesBucketName).getPublicUrl(item.imagePath!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl == null
        ? Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 6),
                  Text(formatCurrency(item.price)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

