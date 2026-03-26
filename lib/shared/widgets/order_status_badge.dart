import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    Color? bg;
    Color? fg;

    if (normalized.contains('pending')) {
      bg = Colors.orange.withValues(alpha: 0.15);
      fg = Colors.orange;
    } else if (normalized.contains('confirmed') || normalized.contains('accepted')) {
      bg = Colors.blue.withValues(alpha: 0.15);
      fg = Colors.blue;
    } else if (normalized.contains('preparing') || normalized.contains('processing')) {
      bg = Colors.purple.withValues(alpha: 0.15);
      fg = Colors.purple;
    } else if (normalized.contains('delivered') || normalized.contains('completed')) {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.green;
    } else if (normalized.contains('cancel') || normalized.contains('rejected')) {
      bg = Colors.red.withValues(alpha: 0.15);
      fg = Colors.red;
    }

    bg ??= Theme.of(context).colorScheme.surfaceContainerHighest;
    fg ??= Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
      ),
    );
  }
}

