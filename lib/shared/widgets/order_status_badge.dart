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
    String label = status;

    if (normalized.contains('pending') || normalized.contains('confirmed')) {
      bg = Colors.orange.withValues(alpha: 0.15);
      fg = Colors.orange;
      label = 'Waiting for confirmation';
    } else if (normalized.contains('accepted') || normalized.contains('preparing') || normalized.contains('in_progress') || normalized.contains('processing')) {
      bg = Colors.blue.withValues(alpha: 0.15);
      fg = Colors.blue;
      label = 'Making the order';
    } else if (normalized.contains('ready')) {
      bg = Colors.purple.withValues(alpha: 0.15);
      fg = Colors.purple;
      label = 'Your order is ready';
    } else if (normalized.contains('delivered') || normalized.contains('completed')) {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.green;
      label = 'Completed';
    } else if (normalized.contains('cancel') || normalized.contains('rejected') || normalized.contains('declined')) {
      bg = Colors.red.withValues(alpha: 0.15);
      fg = Colors.red;
      label = 'Your order was declined. Your refund will be issued shortly.';
    }

    bg ??= Theme.of(context).colorScheme.surfaceContainerHighest;
    fg ??= Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
        textAlign: TextAlign.center,
      ),
    );
  }
}

