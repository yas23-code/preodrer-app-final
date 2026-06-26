import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// An animated number counter that transitions smoothly between values.
///
/// When [value] changes, the old number slides up and fades out while
/// the new number slides in from below. Large numbers are automatically
/// formatted with commas (e.g. 1,234).
///
/// ```dart
/// AnimatedCounter(
///   value: cartItemCount,
///   style: Theme.of(context).textTheme.titleLarge,
/// )
/// ```
class AnimatedCounter extends StatefulWidget {
  /// The integer value to display.
  final int value;

  /// Text style for the counter. Falls back to the default text style.
  final TextStyle? style;

  /// Duration of the slide + fade transition.
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;

  int _previousValue = 0;
  int _currentValue = 0;

  static final NumberFormat _formatter = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _previousValue = widget.value;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<double>(begin: 0, end: -1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fadeOutAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _currentValue = widget.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        widget.style ?? DefaultTextStyle.of(context).style;

    // When the animation is at rest (not animating), just show the value.
    if (!_controller.isAnimating && _controller.value == 0) {
      return Text(
        _formatter.format(_currentValue),
        style: effectiveStyle,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outgoing (old value) — slides up + fades out
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 20),
                child: Opacity(
                  opacity: _fadeOutAnimation.value,
                  child: Text(
                    _formatter.format(_previousValue),
                    style: effectiveStyle,
                  ),
                ),
              ),
              // Incoming (new value) — slides up from below + fades in
              Transform.translate(
                offset: Offset(0, (_slideAnimation.value + 1) * 20),
                child: Opacity(
                  opacity: _fadeInAnimation.value,
                  child: Text(
                    _formatter.format(_currentValue),
                    style: effectiveStyle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
