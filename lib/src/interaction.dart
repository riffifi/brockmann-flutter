import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'feedback.dart';

/// Shared by the page switcher and regions whose pointers it must not claim.
class BrockmannGestureScope extends InheritedWidget {
  const BrockmannGestureScope({
    super.key,
    required this.pointers,
    required super.child,
  });
  final Set<int> pointers;
  static Set<int>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BrockmannGestureScope>()
      ?.pointers;
  @override
  bool updateShouldNotify(BrockmannGestureScope oldWidget) =>
      pointers != oldWidget.pointers;
}

/// A direct-manipulation surface owns gestures that begin inside it. Page
/// swipes remain available outside it, including ordinary page whitespace.
class BrockmannInteractionRegion extends StatelessWidget {
  const BrockmannInteractionRegion({
    super.key,
    required this.child,
    this.enabled = true,
  });
  final Widget child;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final pointers = BrockmannGestureScope.of(context);
    return Listener(
      onPointerDown: (e) => pointers?.add(e.pointer),
      onPointerPanZoomStart: (e) => pointers?.add(e.pointer),
      onPointerPanZoomEnd: (e) => pointers?.remove(e.pointer),
      onPointerUp: (e) => pointers?.remove(e.pointer),
      onPointerCancel: (e) => pointers?.remove(e.pointer),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: 2)),
        child: child,
      ),
    );
  }
}

/// One OS-respecting tactile pickup when holding or grabbing a handle. No
/// continuous ticks, sound, or repeated impact during the same pointer gesture.
class BrockmannHandleFeedback extends StatefulWidget {
  const BrockmannHandleFeedback({
    super.key,
    required this.child,
    required this.isHandle,
    this.enabled = true,
  });
  final Widget child;
  final bool enabled;
  final bool Function(Offset local, Size size) isHandle;
  @override
  State<BrockmannHandleFeedback> createState() =>
      _BrockmannHandleFeedbackState();
}

class _BrockmannHandleFeedbackState extends State<BrockmannHandleFeedback> {
  Timer? _timer;
  Offset? _start;
  int? _pointer;
  bool _fired = false;
  void fire() {
    _timer?.cancel();
    if (_fired || !mounted) return;
    _fired = true;
    BrockmannFeedbackScope.of(context)?.gesture(lifting: true);
  }

  void end() {
    _timer?.cancel();
    _start = null;
    _pointer = null;
    _fired = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: !widget.enabled
        ? null
        : (e) {
            if (_pointer != null) return;
            final box = context.findRenderObject() as RenderBox;
            if (!widget.isHandle(box.globalToLocal(e.position), box.size)) {
              return;
            }
            _pointer = e.pointer;
            _start = e.position;
            _fired = false;
            _timer = Timer(const Duration(milliseconds: 160), fire);
          },
    onPointerMove: (e) {
      if (e.pointer != _pointer || _start == null) return;
      final delta = e.position - _start!;
      if (!_fired && delta.dy.abs() > 8 && delta.dy.abs() > delta.dx.abs()) {
        _timer?.cancel();
        _start = null;
      } else if (delta.dx.abs() > 8) {
        fire();
      }
    },
    onPointerUp: (e) {
      if (e.pointer == _pointer) end();
    },
    onPointerCancel: (e) {
      if (e.pointer == _pointer) end();
    },
    child: widget.child,
  );
}
