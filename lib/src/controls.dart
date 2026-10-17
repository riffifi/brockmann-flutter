import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'foundation.dart';
import 'feedback.dart';
import 'motion.dart';

enum BrockmannButtonStyle { primary, secondary, text }

class BrockmannButton extends StatelessWidget {
  const BrockmannButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = BrockmannButtonStyle.secondary,
    this.sound,
  });
  final String label;
  final VoidCallback? onPressed;
  final BrockmannButtonStyle style;
  final BrockmannSound? sound;
  @override
  Widget build(BuildContext context) => BrockmannPressable(
    label: label,
    tiltStrength: 1,
    onPressed: onPressed,
    sound:
        sound ??
        (style == BrockmannButtonStyle.primary
            ? BrockmannSound.activate
            : null),
    builder: (c, p) {
      final t = c.brockmann;
      final enabled = onPressed != null;
      return AnimatedContainer(
        duration: t.duration(c, p ? 60 : 160),
        padding: EdgeInsets.symmetric(
          horizontal: style == BrockmannButtonStyle.text ? 0 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: style == BrockmannButtonStyle.primary
              ? (enabled
                    ? Color.lerp(t.accent, Colors.black, p ? .18 : 0)
                    : t.line)
              : p
              ? t.surface
              : null,
          border: style == BrockmannButtonStyle.secondary
              ? Border.all(color: enabled ? t.lineStrong : t.line, width: 2)
              : null,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          heightFactor: 1,
          child: BrockmannText(
            label,
            role: style == BrockmannButtonStyle.text
                ? BrockmannType.body
                : BrockmannType.value,
            color: !enabled
                ? t.disabled
                : style == BrockmannButtonStyle.primary
                ? t.onAccent
                : t.foreground,
          ),
        ),
      );
    },
  );
}

class BrockmannSwitch extends StatefulWidget {
  const BrockmannSwitch({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.sound = true,
  });
  final String label;
  final bool value, sound;
  final ValueChanged<bool>? onChanged;
  @override
  State<BrockmannSwitch> createState() => _BrockmannSwitchState();
}

class _BrockmannSwitchState extends State<BrockmannSwitch> {
  double? _drag;
  double _dragStart = 0, _dragDelta = 0;
  void _commit(bool value) {
    if (value == widget.value || widget.onChanged == null) return;
    if (widget.sound) {
      BrockmannFeedbackScope.play(
        context,
        value ? BrockmannSound.toggleOn : BrockmannSound.toggleOff,
      );
    }
    widget.onChanged!(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.brockmann;
    return BrockmannPressable(
      label: widget.label,
      button: false,
      toggled: widget.value,
      onKey: widget.onChanged == null
          ? null
          : (key) {
              if (key == LogicalKeyboardKey.arrowLeft) _commit(false);
              if (key == LogicalKeyboardKey.arrowRight) _commit(true);
            },
      onPressed: widget.onChanged == null ? null : () => _commit(!widget.value),
      builder: (c, pressed) => BrockmannMotion(
        value: _drag ?? (widget.value ? 1 : 0),
        milliseconds: 180,
        immediate: _drag != null,
        builder: (c, raw) {
          final progress = raw.clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrockmannText(
                        widget.label,
                        color: widget.onChanged == null
                            ? t.disabled
                            : t.secondary,
                      ),
                      AnimatedSwitcher(
                        duration: t.duration(c, 170),
                        reverseDuration: t.duration(c, 90),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, ?current],
                        ),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: Offset(0, t.motionReduced(c) ? 0 : -.25),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: BrockmannText(
                          progress >= .5 ? 'On' : 'Off',
                          key: ValueKey(progress >= .5),
                          role: BrockmannType.value,
                          color: widget.onChanged == null
                              ? t.disabled
                              : t.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: widget.onChanged == null
                      ? null
                      : (_) {
                          _dragStart = progress;
                          _dragDelta = 0;
                          setState(() => _drag = progress);
                        },
                  onHorizontalDragUpdate: widget.onChanged == null
                      ? null
                      : (d) {
                          _dragDelta += d.delta.dx;
                          setState(
                            () => _drag = (_dragStart + _dragDelta / 28).clamp(
                              0,
                              1,
                            ),
                          );
                        },
                  onHorizontalDragEnd: widget.onChanged == null
                      ? null
                      : (d) {
                          final velocity = d.velocity.pixelsPerSecond.dx;
                          final next = velocity.abs() > 600
                              ? velocity > 0
                              : (_drag ?? progress) >= .5;
                          _commit(next);
                          setState(() => _drag = null);
                        },
                  onHorizontalDragCancel: () => setState(() => _drag = null),
                  child: SizedBox(
                    width: 60,
                    height: 48,
                    child: BrockmannMotion(
                      value: pressed ? 1 : 0,
                      milliseconds: pressed ? 60 : 220,
                      builder: (c, press) => CustomPaint(
                        painter: _SwitchPainter(
                          progress: progress,
                          press: press.clamp(0, 1),
                          theme: t,
                          enabled: widget.onChanged != null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SwitchPainter extends CustomPainter {
  _SwitchPainter({
    required this.progress,
    required this.press,
    required this.theme,
    required this.enabled,
  });
  final double progress, press;
  final BrockmannThemeData theme;
  final bool enabled;
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(4, (size.height - 20) / 2, 52, 20);
    canvas.drawRect(
      r,
      Paint()
        ..color = enabled
            ? Color.lerp(theme.lineStrong, theme.accent, progress)!
            : theme.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (enabled) {
      canvas.drawRect(
        Rect.fromLTWH(r.left, r.top, r.width * progress, r.height),
        Paint()..color = theme.accent,
      );
      canvas.drawRect(
        r.deflate(2),
        Paint()..color = theme.accent.withValues(alpha: .25 * press),
      );
    }
    final width = 12 + 4 * press;
    final x = r.left + 6 + progress * 28 - (progress > .5 ? width - 12 : 0);
    canvas.drawRect(
      Rect.fromLTWH(x, r.top - 4, width, 28),
      Paint()..color = enabled ? theme.foreground : theme.disabled,
    );
  }

  @override
  bool shouldRepaint(_SwitchPainter old) =>
      old.progress != progress ||
      old.press != press ||
      old.theme != theme ||
      old.enabled != enabled;
}

class BrockmannSlider extends StatefulWidget {
  const BrockmannSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.step,
    this.defaultValue,
    this.formatValue,
  }) : assert(max > min),
       assert(value >= min && value <= max);
  final String label;
  final double value, min, max;
  final double? step, defaultValue;
  final ValueChanged<double>? onChanged;
  final String Function(double)? formatValue;
  @override
  State<BrockmannSlider> createState() => _BrockmannSliderState();
}

class _BrockmannSliderState extends State<BrockmannSlider> {
  bool _direct = false;
  String get readout =>
      widget.formatValue?.call(widget.value) ??
      widget.value.toStringAsFixed(widget.max - widget.min <= 10 ? 2 : 0);
  double quantize(double v) {
    v = v.clamp(widget.min, widget.max);
    return widget.step == null
        ? v
        : (widget.min +
                  ((v - widget.min) / widget.step!).round() * widget.step!)
              .clamp(widget.min, widget.max);
  }

  void adjust(double delta) =>
      widget.onChanged?.call(quantize(widget.value + delta));
  @override
  Widget build(BuildContext context) {
    final t = context.brockmann;
    final enabled = widget.onChanged != null;
    return BrockmannMotion(
      value: widget.value,
      immediate: _direct,
      milliseconds: 240,
      builder: (context, visual) => Semantics(
        label: widget.label,
        value: readout,
        slider: true,
        enabled: enabled,
        increasedValue:
            widget.formatValue?.call(
              quantize(
                widget.value + (widget.step ?? (widget.max - widget.min) / 100),
              ),
            ) ??
            '${quantize(widget.value + (widget.step ?? (widget.max - widget.min) / 100))}',
        decreasedValue:
            '${quantize(widget.value - (widget.step ?? (widget.max - widget.min) / 100))}',
        onIncrease: enabled
            ? () => adjust(widget.step ?? (widget.max - widget.min) / 100)
            : null,
        onDecrease: enabled
            ? () => adjust(-(widget.step ?? (widget.max - widget.min) / 100))
            : null,
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent || !enabled) {
              return KeyEventResult.ignored;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              adjust(-(widget.step ?? (widget.max - widget.min) / 100));
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              adjust(widget.step ?? (widget.max - widget.min) / 100);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: BrockmannText(
                        widget.label,
                        color: enabled ? t.secondary : t.disabled,
                      ),
                    ),
                    const SizedBox(width: 16),
                    BrockmannText(
                      widget.formatValue?.call(visual) ??
                          visual.toStringAsFixed(
                            widget.max - widget.min <= 10 ? 2 : 0,
                          ),
                      role: BrockmannType.monoValue,
                      color: enabled ? t.foreground : t.disabled,
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (c, b) {
                  void set(Offset p) {
                    setState(() => _direct = true);
                    widget.onChanged?.call(
                      quantize(
                        widget.min +
                            (p.dx / b.maxWidth).clamp(0, 1) *
                                (widget.max - widget.min),
                      ),
                    );
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: enabled
                        ? (d) {
                            set(d.localPosition);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _direct = false);
                            });
                          }
                        : null,
                    onHorizontalDragStart: enabled
                        ? (d) => set(d.localPosition)
                        : null,
                    onHorizontalDragUpdate: enabled
                        ? (d) => set(d.localPosition)
                        : null,
                    onHorizontalDragEnd: (_) => setState(() => _direct = false),
                    onHorizontalDragCancel: () =>
                        setState(() => _direct = false),
                    onDoubleTap: enabled && widget.defaultValue != null
                        ? () {
                            setState(() => _direct = false);
                            widget.onChanged!(widget.defaultValue!);
                          }
                        : null,
                    child: SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _SliderPainter(
                          value:
                              ((visual - widget.min) /
                                      (widget.max - widget.min))
                                  .clamp(0, 1),
                          zero: widget.min < 0 && widget.max > 0
                              ? -widget.min / (widget.max - widget.min)
                              : 0,
                          theme: t,
                          enabled: enabled,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({
    required this.value,
    required this.zero,
    required this.theme,
    required this.enabled,
  });
  final double value, zero;
  final BrockmannThemeData theme;
  final bool enabled;
  @override
  void paint(Canvas c, Size s) {
    final y = s.height / 2;
    c.drawRect(
      Rect.fromLTWH(0, y - 1, s.width, 2),
      Paint()..color = theme.lineStrong,
    );
    final a = math.min(zero, value) * s.width,
        b = math.max(zero, value) * s.width;
    c.drawRect(
      Rect.fromLTWH(a, y - 3, b - a, 6),
      Paint()..color = enabled ? theme.accent : theme.disabled,
    );
    c.drawRect(
      Rect.fromLTWH(
        (value * s.width - 6).clamp(0, s.width - 12),
        y - 14,
        12,
        28,
      ),
      Paint()..color = enabled ? theme.foreground : theme.disabled,
    );
  }

  @override
  bool shouldRepaint(covariant _SliderPainter o) =>
      o.value != value ||
      o.theme != theme ||
      o.enabled != enabled ||
      o.zero != zero;
}

class BrockmannKnob extends StatefulWidget {
  const BrockmannKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.defaultValue,
    this.formatValue,
  }) : assert(max > min),
       assert(value >= min && value <= max);
  final String label;
  final double value, min, max;
  final double? defaultValue;
  final ValueChanged<double>? onChanged;
  final String Function(double)? formatValue;
  @override
  State<BrockmannKnob> createState() => _BrockmannKnobState();
}

class _BrockmannKnobState extends State<BrockmannKnob> {
  double _dragValue = 0;
  bool _dragging = false;
  @override
  Widget build(BuildContext context) {
    final t = context.brockmann;
    final enabled = widget.onChanged != null;
    final readout =
        widget.formatValue?.call(widget.value) ??
        widget.value.toStringAsFixed(widget.max - widget.min > 10 ? 0 : 2);
    return Semantics(
      label: widget.label,
      value: readout,
      slider: true,
      enabled: enabled,
      increasedValue:
          '${(widget.value + (widget.max - widget.min) / 100).clamp(widget.min, widget.max)}',
      decreasedValue:
          '${(widget.value - (widget.max - widget.min) / 100).clamp(widget.min, widget.max)}',
      onIncrease: enabled
          ? () => widget.onChanged!(
              (widget.value + (widget.max - widget.min) / 100).clamp(
                widget.min,
                widget.max,
              ),
            )
          : null,
      onDecrease: enabled
          ? () => widget.onChanged!(
              (widget.value - (widget.max - widget.min) / 100).clamp(
                widget.min,
                widget.max,
              ),
            )
          : null,
      child: Focus(
        onKeyEvent: (node, event) {
          if (!enabled || event is! KeyDownEvent) return KeyEventResult.ignored;
          final key = event.logicalKey;
          final step =
              (widget.max - widget.min) /
              100 *
              (HardwareKeyboard.instance.isShiftPressed ? .1 : 1);
          double? next;
          if (key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowDown) {
            next = widget.value - step;
          }
          if (key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.arrowUp) {
            next = widget.value + step;
          }
          if (key == LogicalKeyboardKey.home) next = widget.min;
          if (key == LogicalKeyboardKey.end) next = widget.max;
          if (key == LogicalKeyboardKey.backspace) next = widget.defaultValue;
          if (next == null) return KeyEventResult.ignored;
          widget.onChanged!(next.clamp(widget.min, widget.max));
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: enabled
              ? (_) {
                  _dragValue = widget.value;
                  setState(() => _dragging = true);
                }
              : null,
          onPanEnd: (_) => setState(() => _dragging = false),
          onPanCancel: () => setState(() => _dragging = false),
          onPanUpdate: enabled
              ? (d) {
                  _dragValue =
                      (_dragValue -
                              d.delta.dy /
                                  200 *
                                  (widget.max - widget.min) *
                                  (HardwareKeyboard.instance.isShiftPressed
                                      ? .1
                                      : 1))
                          .clamp(widget.min, widget.max);
                  widget.onChanged!(_dragValue);
                }
              : null,
          onDoubleTap: enabled && widget.defaultValue != null
              ? () => widget.onChanged!(widget.defaultValue!)
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96, minHeight: 112),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: BrockmannMotion(
                    value: widget.value,
                    immediate: _dragging,
                    builder: (c, visual) => CustomPaint(
                      painter: _KnobPainter(
                        ((visual - widget.min) / (widget.max - widget.min))
                            .clamp(0, 1),
                        t,
                        enabled,
                      ),
                      child: Center(
                        child: ExcludeSemantics(
                          child: BrockmannText(
                            widget.formatValue?.call(visual) ??
                                visual.toStringAsFixed(
                                  widget.max - widget.min > 10 ? 0 : 2,
                                ),
                            role: BrockmannType.monoValue,
                            color: enabled ? t.foreground : t.disabled,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                BrockmannText(
                  widget.label,
                  role: BrockmannType.label,
                  color: enabled ? t.secondary : t.disabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter(this.value, this.theme, this.enabled);
  final double value;
  final BrockmannThemeData theme;
  final bool enabled;
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(10, 10, s.width - 20, s.height - 20);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    c.drawArc(r, math.pi * .75, math.pi * 1.5, false, p..color = theme.line);
    c.drawArc(
      r,
      math.pi * .75,
      math.pi * 1.5 * value,
      false,
      p..color = enabled ? theme.accent : theme.disabled,
    );
    final angle = math.pi * .75 + math.pi * 1.5 * value,
        center = s.center(Offset.zero);
    c.drawLine(
      center + Offset(math.cos(angle), math.sin(angle)) * 22,
      center + Offset(math.cos(angle), math.sin(angle)) * 31,
      Paint()
        ..color = enabled ? theme.foreground : theme.disabled
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _KnobPainter o) =>
      o.value != value || o.theme != theme || o.enabled != enabled;
}

class BrockmannTextField extends StatelessWidget {
  const BrockmannTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.error,
    this.enabled = true,
    this.multiline = false,
    this.keyboardType,
    this.obscureText = false,
  }) : assert(controller == null || initialValue == null);
  final String label;
  final TextEditingController? controller;
  final String? initialValue, error;
  final ValueChanged<String>? onChanged;
  final bool enabled, multiline, obscureText;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) {
    final t = context.brockmann;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrockmannText(
          label,
          role: BrockmannType.label,
          color: enabled ? t.secondary : t.disabled,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          enabled: enabled,
          obscureText: obscureText,
          minLines: multiline ? 3 : 1,
          maxLines: multiline ? 8 : 1,
          keyboardType:
              keyboardType ??
              (multiline ? TextInputType.multiline : TextInputType.text),
          style: (multiline ? BrockmannType.monoValue : BrockmannType.body)
              .style(color: t.foreground),
          cursorColor: t.accent,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
            errorText: error,
            errorMaxLines: 3,
            errorStyle: BrockmannType.caption.style(color: t.danger),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: t.lineStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: t.lineStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: t.accent, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: t.line),
            ),
          ),
        ),
      ],
    );
  }
}
