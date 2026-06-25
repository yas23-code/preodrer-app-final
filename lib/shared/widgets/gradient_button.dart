import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

/// A reusable gradient action button with loading & disabled states.
///
/// Renders a 52px-tall button filled with a [gradient] (defaults to
/// [AppColors.primaryGradient]). When [isLoading] is `true`, the label
/// is replaced with a white [CircularProgressIndicator]. When [onPressed]
/// is `null`, the button opacity is reduced to 0.5.
///
/// ```dart
/// GradientButton(
///   label: 'Place Order',
///   icon: Icons.shopping_bag_outlined,
///   isLoading: isSubmitting,
///   onPressed: isValid ? _submit : null,
/// )
/// ```
class GradientButton extends StatelessWidget {
  /// Button label text.
  final String label;

  /// Callback when the button is pressed.
  ///
  /// Pass `null` to disable the button (opacity 0.5, no ink splash).
  final VoidCallback? onPressed;

  /// Whether to show a loading indicator instead of the label.
  final bool isLoading;

  /// Optional leading icon.
  final IconData? icon;

  /// The gradient used for the button background.
  ///
  /// Defaults to [AppColors.primaryGradient].
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient,
  });

  bool get _isDisabled => onPressed == null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppColors.primaryGradient;

    return AnimatedOpacity(
      opacity: _isDisabled ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: AppShadows.borderRadiusFull,
          boxShadow: _isDisabled ? null : AppShadows.primaryGlow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: AppShadows.borderRadiusFull,
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _buildLabel(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel() {
    final style = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: style),
        ],
      );
    }

    return Text(label, style: style);
  }
}
