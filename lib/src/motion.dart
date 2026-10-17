import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

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

class _OutgoingPage {
  const _OutgoingPage(
    this.key,
    this.child,
    this.back,
    this.offset,
    this.exitDelta,
  );
  final Key key;
  final Widget child;
  final bool back;
  final double offset, exitDelta;
}

class _BrockmannPageSwitcherState extends State<BrockmannPageSwitcher>
    with SingleTickerProviderStateMixin {
  late final _slide = AnimationController.unbounded(vsync: this)
    ..addListener(() {
      if (mounted) setState(() {});
    });
  bool _swipeCommit = false;
  double _width = 0;
  void _settle() => _slide.animateTo(
    0,
    duration: context.brockmann.duration(context, 240),
    curve: brockmannOutExpo,
  );
  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  final _outgoing = <_OutgoingPage>[];
  Key _current = UniqueKey();
  bool _animateEntrance = false;
  double _drag = 0;
  @override
  void didUpdateWidget(BrockmannPageSwitcher old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      _outgoing.add(
        _OutgoingPage(
          _current,
          old.child,
          widget.selected < old.selected,
          _slide.value,
          _swipeCommit
              ? (widget.selected > old.selected ? -_width : _width) -
                    _slide.value
              : 0,
        ),
      );
      _current = UniqueKey();
      _animateEntrance = !_swipeCommit;
      if (_swipeCommit) {
        _slide.value += widget.selected > old.selected ? _width : -_width;
        _swipeCommit = false;
        _settle();
      } else {
        _slide.value = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _width = constraints.maxWidth;
      return GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: widget.onChanged == null
            ? null
            : (_) {
                _drag = 0;
                _slide.stop();
              },
        onHorizontalDragUpdate: widget.onChanged == null
            ? null
            : (d) {
                _drag += d.delta.dx;
                _slide.value += d.delta.dx;
              },
        onHorizontalDragEnd: widget.onChanged == null
            ? null
            : (d) {
                if (_drag.abs() > 80 ||
                    d.velocity.pixelsPerSecond.dx.abs() > 600) {
                  final direction = d.velocity.pixelsPerSecond.dx.abs() > 600
                      ? d.velocity.pixelsPerSecond.dx
                      : _drag;
                  final next = (widget.selected + (direction < 0 ? 1 : -1))
                      .clamp(0, widget.pageCount - 1);
                  if (next != widget.selected) {
                    _swipeCommit = true;
                    widget.onChanged!(next);
                    return;
                  }
                }
                _settle();
              },
        onHorizontalDragCancel: _settle,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final page in _outgoing)
                _PageTransition(
                  key: page.key,
                  offset: page.offset,
                  exitDelta: page.exitDelta,
                  exiting: true,
                  back: page.back,
                  animateEntrance: true,
                  onFinished: () {
                    if (mounted) setState(() => _outgoing.remove(page));
                  },
                  child: page.child,
                ),
              _PageTransition(
                key: _current,
                offset: _slide.value,
                exiting: false,
                back: false,
                animateEntrance: _animateEntrance,
                child: widget.child,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PageTransition extends StatefulWidget {
  const _PageTransition({
    super.key,
    required this.exiting,
    required this.back,
    required this.animateEntrance,
    required this.child,
    this.onFinished,
    this.offset = 0,
    this.exitDelta = 0,
  });
  final double offset, exitDelta;
  final bool exiting, back, animateEntrance;
  final Widget child;
  final VoidCallback? onFinished;
  @override
  State<_PageTransition> createState() => _PageTransitionState();
}

class _PageTransitionState extends State<_PageTransition>
    with TickerProviderStateMixin {
  late final _entry = AnimationController(
    vsync: this,
    value: widget.animateEntrance ? 0 : 1,
  );
  late final _exit = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished?.call();
    });
  late final _frames = Listenable.merge([_entry, _exit]);
  Animation<double>? _frozen;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _entry.duration = context.brockmann.duration(context, 580);
      if (widget.animateEntrance) _entry.forward();
    }
  }

  @override
  void didUpdateWidget(_PageTransition old) {
    super.didUpdateWidget(old);
    if (widget.exiting && !old.exiting) {
      _frozen = AlwaysStoppedAnimation(_entry.value);
      _entry.stop();
      _exit.duration = context.brockmann.duration(
        context,
        widget.exitDelta == 0 ? 250 : 240,
      );
      _exit.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _frames,
    child: RepaintBoundary(child: widget.child),
    builder: (c, child) {
      final reduced = c.brockmann.motionReduced(c);
      final swipeExit = widget.exitDelta != 0;
      final t = (swipeExit ? brockmannOutExpo : brockmannInExpo).transform(
        _exit.value,
      );
      final matrix = Matrix4.identity()..setEntry(3, 2, -1 / 800);
      if (!reduced) {
        matrix.translateByDouble(widget.offset + widget.exitDelta * t, 0, 0, 1);
      }
      if (widget.exiting && !reduced && !swipeExit) {
        matrix.rotateY((widget.back ? -1 : 1) * 50 * math.pi / 180 * t);
      }
      return IgnorePointer(
        ignoring: widget.exiting,
        child: ExcludeSemantics(
          excluding: widget.exiting,
          child: ExcludeFocus(
            excluding: widget.exiting,
            child: Transform(
              alignment: Alignment.centerLeft,
              transform: matrix,
              child: Opacity(
                opacity: widget.exiting
                    ? (swipeExit && !reduced ? 1 : 1 - t)
                    : (reduced ? _entry.value : 1),
                child: TickerMode(
                  enabled: !widget.exiting,
                  child: _PageMotion(
                    animation: _frozen ?? _entry,
                    child: child!,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
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
