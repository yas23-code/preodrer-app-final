import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Classic Indian Veg / Non-Veg indicator.
///
/// A small square with rounded corners containing a centered filled circle.
/// - **Veg**: green border + green dot ([AppColors.vegGreen])
/// - **Non-Veg**: red border + red dot ([AppColors.nonVegRed])
///
/// Matches the FSSAI-standard label design used across Indian food apps.
///
/// ```dart
/// VegIndicator(isVeg: true)
/// VegIndicator(isVeg: false, size: 20)
/// ```
class VegIndicator extends StatelessWidget {
  /// Whether the item is vegetarian.
  final bool isVeg;

  /// Overall size of the outer square. Defaults to `16`.
  final double size;

  const VegIndicator({
    super.key,
    required this.isVeg,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.vegGreen : AppColors.nonVegRed;
    final dotSize = size * 0.4;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
