import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A vertical animated order-status timeline widget.
///
/// Displays five steps: Placed → Confirmed → Preparing → Ready → Completed.
/// - Completed steps show a filled green dot with a solid green connector.
/// - The current step pulses with a subtle scale animation.
/// - Future steps are outlined in grey with grey connectors.
/// - Cancelled / declined orders show a red ✕ at the failed step.
///
/// Usage:
/// ```dart
/// OrderTimeline(currentStatus: 'preparing')
/// ```
class OrderTimeline extends StatefulWidget {
  /// The current order status string (case-insensitive).
  ///
  /// Recognized values:
  /// `pending` → step 0, `confirmed` → step 1,
  /// `accepted|preparing|processing|in_progress` → step 2,
  /// `ready` → step 3, `completed|delivered` → step 4,
  /// `cancelled|declined|rejected` → shows a red ✕.
  final String currentStatus;

  /// Optional map of step index → timestamp string to display beside each
  /// completed step.
  final Map<int, String>? timestamps;

  const OrderTimeline({
    super.key,
    required this.currentStatus,
    this.timestamps,
  });

  @override
  State<OrderTimeline> createState() => _OrderTimelineState();
}

class _OrderTimelineState extends State<OrderTimeline>
    with TickerProviderStateMixin {
  // ── Step definitions ──────────────────────────────────────────────
  static const List<_TimelineStep> _steps = [
    _TimelineStep(label: 'Placed', icon: Icons.receipt_long_rounded),
    _TimelineStep(label: 'Confirmed', icon: Icons.check_circle_outline_rounded),
    _TimelineStep(label: 'Preparing', icon: Icons.restaurant_rounded),
    _TimelineStep(label: 'Ready', icon: Icons.takeout_dining_rounded),
    _TimelineStep(label: 'Completed', icon: Icons.done_all_rounded),
  ];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _entryController;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  int _activeIndex = -1;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _resolveStatus();

    // Pulse animation for the current step dot.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Staggered entry animations.
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimations = List.generate(_steps.length, (i) {
      final start = i / _steps.length;
      final end = math.min(start + 0.4, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(_steps.length, (i) {
      final start = i / _steps.length;
      final end = math.min(start + 0.4, 1.0);
      return Tween<Offset>(
        begin: const Offset(0.0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _entryController.forward();
  }

  @override
  void didUpdateWidget(covariant OrderTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _resolveStatus();
    }
  }

  void _resolveStatus() {
    final status = widget.currentStatus.toLowerCase().trim();
    _isCancelled = false;

    if (status.contains('cancel') ||
        status.contains('declined') ||
        status.contains('rejected')) {
      _isCancelled = true;
      // Show the red marker at the latest reached step (default to 0).
      if (status.contains('ready')) {
        _activeIndex = 3;
      } else if (status.contains('prepar') ||
          status.contains('accept') ||
          status.contains('process') ||
          status.contains('in_progress')) {
        _activeIndex = 2;
      } else if (status.contains('confirm')) {
        _activeIndex = 1;
      } else {
        _activeIndex = 0;
      }
      return;
    }

    if (status.contains('completed') || status.contains('delivered')) {
      _activeIndex = 4;
    } else if (status.contains('ready')) {
      _activeIndex = 3;
    } else if (status.contains('prepar') ||
        status.contains('accept') ||
        status.contains('process') ||
        status.contains('in_progress')) {
      _activeIndex = 2;
    } else if (status.contains('confirm')) {
      _activeIndex = 1;
    } else {
      // Default / pending
      _activeIndex = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greyColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final isCompleted = i < _activeIndex;
        final isCurrent = i == _activeIndex;
        final isFuture = i > _activeIndex;
        final isLast = i == _steps.length - 1;

        return FadeTransition(
          opacity: _fadeAnimations[i],
          child: SlideTransition(
            position: _slideAnimations[i],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dot + Connector column ──────────────────────
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      _buildDot(
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        isFuture: isFuture,
                        greyColor: greyColor,
                      ),
                      if (!isLast)
                        _buildConnector(
                          isCompleted: isCompleted,
                          greyColor: greyColor,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ── Label + Timestamp ───────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: AppTypography.titleSmall.copyWith(
                            color: isFuture ? greyColor : textColor,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        if (widget.timestamps != null &&
                            widget.timestamps!.containsKey(i))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.timestamps![i]!,
                              style: AppTypography.bodySmall.copyWith(
                                color: subtextColor,
                              ),
                            ),
                          ),
                        if (_isCancelled && isCurrent)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Order was cancelled',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Dot ────────────────────────────────────────────────────────────
  Widget _buildDot({
    required bool isCompleted,
    required bool isCurrent,
    required bool isFuture,
    required Color greyColor,
  }) {
    const double size = 22;

    // Cancelled / declined → red ✕
    if (_isCancelled && isCurrent) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.error.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.error, width: 2),
        ),
        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
      );
    }

    // Completed step → filled green dot with check
    if (isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    }

    // Current step → pulsing dot
    if (isCurrent) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.accent, width: 2.5),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      );
    }

    // Future step → outlined grey
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: greyColor, width: 1.5),
      ),
    );
  }

  // ── Connector line ────────────────────────────────────────────────
  Widget _buildConnector({
    required bool isCompleted,
    required Color greyColor,
  }) {
    const double height = 28;

    if (isCompleted) {
      // Solid green line
      return Container(
        width: 2.5,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    // Dashed grey line
    return SizedBox(
      width: 2.5,
      height: height,
      child: CustomPaint(
        painter: _DashedLinePainter(color: greyColor),
      ),
    );
  }
}

// ── Step data class ──────────────────────────────────────────────────
class _TimelineStep {
  final String label;
  final IconData icon;

  const _TimelineStep({required this.label, required this.icon});
}

// ── Dashed-line painter ──────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;

    const dashHeight = 4.0;
    const dashGap = 3.0;
    double y = 0;

    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, math.min(y + dashHeight, size.height)),
        paint,
      );
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
