import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'foundation.dart';
import 'feedback.dart';
import 'motion.dart';

@immutable
class BrockmannColorScheme {
  const BrockmannColorScheme(
    this.name,
    this.primary, {
    this.companions = const [],
  });
  final String name;
  final Color primary;
  final List<Color> companions;
  String get hex => colorHex(primary);
}

String colorHex(Color color) =>
    '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';

enum BrockmannPaletteVariant { ribbon, swatches, grid }

List<BrockmannColorScheme> windows8Palette() {
  const colors = <String, int>{
    'gold': 0xc6b324,
    'olive': 0x718c31,
    'slate blue': 0x375c9c,
    'wine': 0x8e243d,
    'plum': 0x682d73,
    'brick': 0x9c332c,
    'rust': 0xb94b18,
    'ruby': 0xbe2044,
    'berry': 0x8c147c,
    'indigo': 0x48249a,
    'navy': 0x183c78,
    'ocean': 0x16739d,
    'forest': 0x13834b,
    'green': 0x38a029,
    'lime': 0x88bf24,
    'tangerine': 0xf89619,
    'coral': 0xee5035,
    'fuchsia': 0xde3986,
    'purple': 0x9c42cb,
    'cobalt': 0x4266cb,
    'sky': 0x239bd5,
    'cyan': 0x2bb7d0,
    'turquoise': 0x34c5be,
    'mint': 0x70c391,
    'chartreuse': 0xc4d53b,
    'yellow': 0xf2c627,
    'orange': 0xe99a32,
    'salmon': 0xdb7465,
    'orchid': 0xc87ba9,
    'periwinkle': 0x8a90d0,
    'sea': 0x4eaaa6,
    'terracotta': 0xc56143,
  };
  return colors.entries
      .map((e) {
        final c = Color(0xff000000 | e.value);
        return BrockmannColorScheme(
          e.key,
          c,
          companions: [
            Color.lerp(c, Colors.white, .5)!,
            Color.lerp(c, Colors.black, .45)!,
            Color.from(alpha: 1, red: c.b, green: c.r, blue: c.g),
          ],
        );
      })
      .toList(growable: false);
}

/// Touch-sized colour schemes, including a scaled Windows 8 ribbon.
class BrockmannColorPicker extends StatefulWidget {
  const BrockmannColorPicker({
    super.key,
    required this.label,
    required this.schemes,
    required this.selected,
    required this.onChanged,
    this.variant = BrockmannPaletteVariant.grid,
    this.axis = Axis.horizontal,
    this.companionCount = 0,
    this.verticalExtent = 320,
  }) : assert(selected >= 0),
       assert(companionCount >= 0 && companionCount <= 3);
  final String label;
  final List<BrockmannColorScheme> schemes;
  final int selected, companionCount;
  final ValueChanged<int>? onChanged;
  final BrockmannPaletteVariant variant;
  final Axis axis;
  final double verticalExtent;
  @override
  State<BrockmannColorPicker> createState() => _BrockmannColorPickerState();
}

class _BrockmannColorPickerState extends State<BrockmannColorPicker> {
  int get _selected => widget.schemes.isEmpty
      ? 0
      : widget.selected.clamp(0, widget.schemes.length - 1);
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void didUpdateWidget(BrockmannColorPicker old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected ||
        old.variant != widget.variant ||
        old.axis != widget.axis) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  double get _step =>
      widget.variant == BrockmannPaletteVariant.ribbon ? 48 : 56;
  void _reveal() {
    if (!mounted ||
        widget.variant == BrockmannPaletteVariant.grid ||
        !_scroll.hasClients) {
      return;
    }
    final start = _selected * _step,
        end = start + _step,
        offset = _scroll.offset,
        extent = _scroll.position.viewportDimension;
    final target =
        (start < offset
                ? start
                : end > offset + extent
                ? end - extent
                : offset)
            .clamp(0.0, _scroll.position.maxScrollExtent);
    if (context.brockmann.motionReduced(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: context.brockmann.duration(context, 180),
        curve: brockmannEaseOut,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _choose(int i) {
    if (widget.onChanged == null || i == _selected) return;
    BrockmannFeedbackScope.play(context, BrockmannSound.select);
    widget.onChanged!(i);
  }

  Widget _cell(int i, Size size) {
    final scheme = widget.schemes[i];
    final description =
        '${scheme.name} ${scheme.hex}${scheme.companions.take(widget.companionCount).map((c) => ', companion ${colorHex(c)}').join()}';
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Semantics(
        checked: i == _selected,
        inMutuallyExclusiveGroup: true,
        child: BrockmannPressable(
          label: description,
          button: false,
          onPressed: widget.onChanged == null ? null : () => _choose(i),
          tooltip: description,
          builder: (c, p) => const SizedBox.expand(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.brockmann;
    final selected = widget.schemes.isEmpty ? null : widget.schemes[_selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrockmannText(
          widget.label,
          role: BrockmannType.label,
          color: widget.onChanged == null ? t.disabled : t.secondary,
        ),
        const SizedBox(height: 4),
        BrockmannText(
          selected == null
              ? 'No colours'
              : '${selected.name} / ${selected.hex}',
          role: BrockmannType.monoValue,
        ),
        const SizedBox(height: 12),
        if (selected != null)
          LayoutBuilder(
            builder: (c, b) {
              final grid = widget.variant == BrockmannPaletteVariant.grid,
                  vertical = widget.axis == Axis.vertical && !grid;
              final columns = grid
                  ? math.max(1, (b.maxWidth / 56).floor())
                  : widget.schemes.length;
              final ribbon = widget.variant == BrockmannPaletteVariant.ribbon;
              final crossExtent = ribbon ? 176.0 : 88.0;
              final size = grid
                  ? Size(
                      columns * 56,
                      ((widget.schemes.length + columns - 1) ~/ columns) * 72,
                    )
                  : vertical
                  ? Size(
                      math.min(b.maxWidth, ribbon ? 288 : 144),
                      widget.schemes.length * _step,
                    )
                  : Size(widget.schemes.length * _step, crossExtent);
              final visual = BrockmannMotion(
                value: _selected.toDouble(),
                milliseconds: 180,
                builder: (c, position) => CustomPaint(
                  painter: _PalettePainter(
                    schemes: widget.schemes,
                    variant: widget.variant,
                    vertical: vertical,
                    companions: widget.companionCount,
                    columns: columns,
                    position: t.motionReduced(c)
                        ? _selected.toDouble()
                        : position,
                    theme: t,
                    enabled: widget.onChanged != null,
                  ),
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: grid
                        ? Wrap(
                            children: [
                              for (var i = 0; i < widget.schemes.length; i++)
                                _cell(i, const Size(56, 72)),
                            ],
                          )
                        : vertical
                        ? Column(
                            children: [
                              for (var i = 0; i < widget.schemes.length; i++)
                                _cell(i, Size(size.width, _step)),
                            ],
                          )
                        : Row(
                            children: [
                              for (var i = 0; i < widget.schemes.length; i++)
                                _cell(i, Size(_step, crossExtent)),
                            ],
                          ),
                  ),
                ),
              );
              return grid
                  ? Align(alignment: Alignment.centerLeft, child: visual)
                  : SizedBox(
                      height: vertical ? widget.verticalExtent : crossExtent,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        scrollDirection: widget.axis,
                        child: visual,
                      ),
                    );
            },
          ),
      ],
    );
  }
}

class _PalettePainter extends CustomPainter {
  _PalettePainter({
    required this.schemes,
    required this.variant,
    required this.vertical,
    required this.companions,
    required this.columns,
    required this.position,
    required this.theme,
    required this.enabled,
  });
  final List<BrockmannColorScheme> schemes;
  final BrockmannPaletteVariant variant;
  final bool vertical, enabled;
  final int companions, columns;
  final double position;
  final BrockmannThemeData theme;
  Color muted(Color c) => enabled ? c : Color.lerp(c, theme.background, .65)!;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    if (variant == BrockmannPaletteVariant.ribbon) {
      c.scale(2);
      size = Size(size.width / 2, size.height / 2);
    }
    _paint(c, size);
    c.restore();
  }

  void _paint(Canvas c, Size size) {
    final ribbon = variant == BrockmannPaletteVariant.ribbon,
        grid = variant == BrockmannPaletteVariant.grid;
    final step = ribbon ? 24.0 : 56.0;
    Rect cell(int i) => grid
        ? Rect.fromLTWH((i % columns) * 56, (i ~/ columns) * 72, 56, 72)
        : vertical
        ? Rect.fromLTWH(0, i * step, size.width, step)
        : Rect.fromLTWH(i * step, 0, step, 88);
    for (var i = 0; i < schemes.length; i++) {
      final r = cell(i), s = schemes[i];
      final main = ribbon
          ? (vertical
                ? Rect.fromLTWH(24, r.top, 20, step)
                : Rect.fromLTWH(r.left, 32, step, 20))
          : (vertical
                ? Rect.fromLTWH(12, r.top + 12, 32, 32)
                : Rect.fromLTWH(r.left + 12, r.top + 28, 32, 32));
      c.drawRect(
        main,
        Paint()
          ..color = muted(
            ribbon ? Color.lerp(s.primary, Colors.black, .62)! : s.primary,
          ),
      );
      if (ribbon) {
        c.drawRect(
          Rect.fromCenter(center: main.center, width: 8, height: 8),
          Paint()..color = muted(s.primary),
        );
      } else {
        c.drawRect(
          main,
          Paint()
            ..color = theme.line
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      for (var j = 0; j < math.min(companions, s.companions.length); j++) {
        final a = ribbon
            ? (vertical
                  ? Rect.fromLTWH(50 + j * 8, r.center.dy - 3, 6, 6)
                  : Rect.fromLTWH(r.left + 2 + j * 8, 20, 6, 6))
            : (vertical
                  ? Rect.fromLTWH(52 + j * 16, r.top + 22, 12, 12)
                  : Rect.fromLTWH(r.left + 4 + j * 16, r.top + 10, 12, 12));
        c.drawRect(a, Paint()..color = muted(s.companions[j]));
      }
    }
    if (schemes.isEmpty) return;
    final p = position.clamp(0.0, schemes.length - 1.0);
    final r = Rect.lerp(cell(p.floor()), cell(p.ceil()), p - p.floor())!;
    final stroke = Paint()
      ..color = enabled ? theme.foreground : theme.disabled
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (ribbon) {
      c.drawRect(
        vertical
            ? Rect.fromLTWH(22, 0, 24, size.height)
            : Rect.fromLTWH(.5, 30, size.width - 1, 24),
        Paint()
          ..color = theme.lineStrong
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final top = Path(), bottom = Path();
      if (vertical) {
        top
          ..moveTo(10, r.center.dy - 4)
          ..lineTo(10, r.center.dy + 4)
          ..lineTo(17, r.center.dy)
          ..close();
        final x = companions == 0 ? 50.0 : 56.0 + companions * 8;
        bottom
          ..moveTo(x + 7, r.center.dy - 4)
          ..lineTo(x + 7, r.center.dy + 4)
          ..lineTo(x, r.center.dy)
          ..close();
      } else {
        final y = companions == 0 ? 16.0 : 4.0;
        top
          ..moveTo(r.center.dx - 4, y)
          ..lineTo(r.center.dx + 4, y)
          ..lineTo(r.center.dx, y + 7)
          ..close();
        bottom
          ..moveTo(r.center.dx - 4, 67)
          ..lineTo(r.center.dx + 4, 67)
          ..lineTo(r.center.dx, 60)
          ..close();
      }
      c.drawPath(top, stroke);
      c.drawPath(bottom, stroke);
    } else if (variant == BrockmannPaletteVariant.grid) {
      c.drawRect(r.deflate(2), stroke..strokeWidth = 2);
    } else {
      final first = Path(), second = Path();
      if (vertical) {
        first
          ..moveTo(2, r.center.dy - 4)
          ..lineTo(9, r.center.dy)
          ..lineTo(2, r.center.dy + 4);
        final x = companions == 0 ? 46.0 : 52.0 + companions * 16;
        second
          ..moveTo(x + 7, r.center.dy - 4)
          ..lineTo(x, r.center.dy)
          ..lineTo(x + 7, r.center.dy + 4);
      } else {
        first
          ..moveTo(r.center.dx - 4, r.top)
          ..lineTo(r.center.dx, r.top + 7)
          ..lineTo(r.center.dx + 4, r.top);
        second
          ..moveTo(r.center.dx - 4, r.top + 70)
          ..lineTo(r.center.dx, r.top + 63)
          ..lineTo(r.center.dx + 4, r.top + 70);
      }
      c.drawPath(first, stroke);
      c.drawPath(second, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _PalettePainter old) =>
      old.position != position ||
      old.variant != variant ||
      old.vertical != vertical ||
      old.companions != companions ||
      old.columns != columns ||
      old.theme != theme ||
      old.enabled != enabled ||
      old.schemes != schemes;
}
