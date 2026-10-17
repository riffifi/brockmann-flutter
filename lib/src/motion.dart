import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Same 32-iteration Bézier inversion as the Rust clock. Flutter's stock
/// Cubic solver is too coarse for finite-difference velocity preservation.
class BrockmannCurve extends Curve {
  const BrockmannCurve(this.x1, this.y1, this.x2, this.y2);
  final double x1, y1, x2, y2;
  double _sample(double t, double a, double b) =>
      3 * (1 - t) * (1 - t) * t * a + 3 * (1 - t) * t * t * b + t * t * t;
  @override
  double transformInternal(double t) {
    var lo = 0.0, hi = 1.0;
    for (var i = 0; i < 32; i++) {
      final mid = (lo + hi) / 2;
      if (_sample(mid, x1, x2) < t) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return _sample((lo + hi) / 2, y1, y2);
  }
}

const brockmannOutExpo = BrockmannCurve(.16, 1, .3, 1);
const brockmannInExpo = BrockmannCurve(.7, 0, .84, 0);
const brockmannInOut = BrockmannCurve(.76, 0, .24, 1);

double _slope(Curve curve, double t) {
  final a = (t - .00001).clamp(0.0, 1.0);
  final b = (t + .00001).clamp(0.0, 1.0);
  return (curve.transform(b) - curve.transform(a)) / (b - a);
}

/// Rust's bounded, velocity-continuous tween, driven only while changing.
class BrockmannMotion extends StatefulWidget {
  const BrockmannMotion({
    super.key,
    required this.value,
    required this.builder,
    this.milliseconds = 240,
    this.curve = brockmannOutExpo,
    this.immediate = false,
  });
  final double value;
  final int milliseconds;
  final Curve curve;
  final bool immediate;
  final Widget Function(BuildContext context, double value) builder;
  @override
  State<BrockmannMotion> createState() => _BrockmannMotionState();
}

class _BrockmannMotionState extends State<BrockmannMotion>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(vsync: this, value: 1);
  late double _from = widget.value, _target = widget.value;
  double _correction = 0, _seconds = .24;
  Curve _curve = brockmannOutExpo;
  double get _value {
    final t = _clock.value;
    return _from +
        (_target - _from) * _curve.transform(t) +
        _correction * _seconds * t * math.pow(1 - t, 2);
  }

  double get _velocity {
    if (!_clock.isAnimating) return 0;
    final t = _clock.value;
    return (_target - _from) * _slope(_curve, t) / _seconds +
        _correction * (1 - t) * (1 - 3 * t);
  }

  @override
  void didUpdateWidget(BrockmannMotion old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || (widget.immediate && !old.immediate)) {
      _retarget();
    }
  }

  void _retarget() {
    final active = _clock.isAnimating;
    final position = _value, velocity = _velocity;
    _from = position;
    _target = widget.value;
    _curve = widget.curve;
    final duration = context.brockmann.duration(context, widget.milliseconds);
    _seconds = math.max(.000001, duration.inMicroseconds / 1000000);
    _correction = active
        ? velocity - (_target - _from) * _slope(_curve, 0) / _seconds
        : 0;
    if (widget.immediate) {
      _clock.stop();
      _clock.value = 1;
    } else {
      _clock.duration = duration;
      _clock.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (c, _) => widget.builder(c, _value),
  );
}

class _PageMotion extends InheritedWidget {
  const _PageMotion({required this.animation, required super.child});
  final Animation<double> animation;
  @override
  bool updateShouldNotify(_PageMotion oldWidget) =>
      oldWidget.animation != animation;
}

/// The desktop's outgoing 250 ms turnstile and incoming staggered feather.
/// Give the child a stable page key. Each page must own its scroll viewport.
class BrockmannPageSwitcher extends StatefulWidget {
  const BrockmannPageSwitcher({
    super.key,
    required this.selected,
    required this.child,
    this.onChanged,
    this.pageCount = 1,
  });
  final int selected, pageCount;
  final Widget child;
  final ValueChanged<int>? onChanged;
  @override
  State<BrockmannPageSwitcher> createState() => _BrockmannPageSwitcherState();
}

class _BrockmannPageSwitcherState extends State<BrockmannPageSwitcher> {
  bool _back = false;
  double _drag = 0;
  @override
  void didUpdateWidget(BrockmannPageSwitcher old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _back = widget.selected < old.selected;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.brockmann;
    final reduced = theme.motionReduced(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: widget.onChanged == null ? null : (_) => _drag = 0,
      onHorizontalDragUpdate: widget.onChanged == null
          ? null
          : (d) => _drag += d.delta.dx,
      onHorizontalDragEnd: widget.onChanged == null
          ? null
          : (d) {
              if (_drag.abs() > 80 ||
                  d.velocity.pixelsPerSecond.dx.abs() > 600) {
                final direction = d.velocity.pixelsPerSecond.dx.abs() > 600
                    ? d.velocity.pixelsPerSecond.dx
                    : _drag;
                final next = (widget.selected + (direction < 0 ? 1 : -1)).clamp(
                  0,
                  widget.pageCount - 1,
                );
                if (next != widget.selected) widget.onChanged!(next);
              }
            },
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: theme.duration(context, 580),
          reverseDuration: theme.duration(context, 250),
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          transitionBuilder: (child, animation) {
            var exitStart = 1.0;
            var wasExiting = false;
            Animation<double>? frozen;
            return AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (c, child) {
                final exiting = animation.status == AnimationStatus.reverse;
                if (exiting && !wasExiting) {
                  exitStart = animation.value;
                  frozen = AlwaysStoppedAnimation(exitStart);
                }
                wasExiting = exiting;
                final elapsed = exiting
                    ? (exitStart - animation.value) /
                          math.max(.000001, exitStart)
                    : 0.0;
                final t = brockmannInExpo.transform(elapsed.clamp(0, 1));
                final matrix = Matrix4.identity()..setEntry(3, 2, -1 / 800);
                if (exiting && !reduced) {
                  matrix.rotateY((_back ? -1 : 1) * 50 * math.pi / 180 * t);
                }
                return IgnorePointer(
                  ignoring: exiting,
                  child: ExcludeSemantics(
                    excluding: exiting,
                    child: Transform(
                      alignment: Alignment.centerLeft,
                      transform: matrix,
                      child: Opacity(
                        opacity: exiting
                            ? 1 - t
                            : (reduced ? animation.value : 1),
                        child: _PageMotion(
                          animation: exiting ? frozen! : animation,
                          child: child!,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          child: KeyedSubtree(
            key: ValueKey(widget.selected),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Wrap successive rows to reproduce Rust's 40 ms / 300 ms entry cascade.
class BrockmannFeather extends StatelessWidget {
  const BrockmannFeather({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_PageMotion>();
    if (scope == null) return child;
    return AnimatedBuilder(
      animation: scope.animation,
      child: RepaintBoundary(child: child),
      builder: (c, child) {
        final reduced = c.brockmann.motionReduced(c);
        final elapsed = scope.animation.value * .58;
        final progress = reduced
            ? scope.animation.value
            : brockmannOutExpo.transform(
                ((elapsed - math.min(index, 7) * .04) / .3).clamp(0, 1),
              );
        final matrix = Matrix4.identity()..setEntry(3, 2, -1 / 800);
        if (!reduced) {
          matrix.translateByDouble(
            (index == 0 ? 100 : 60) * (1 - progress),
            0,
            0,
            1,
          );
          matrix.rotateY(-35 * math.pi / 180 * (1 - progress));
        }
        return Opacity(
          opacity: progress,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: matrix,
            child: child,
          ),
        );
      },
    );
  }
}
