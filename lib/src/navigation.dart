import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'foundation.dart';
import 'feedback.dart';
import 'motion.dart';

/// Fitting options never disappear. Overflow pans only enough to reveal selection.
class BrockmannPivot extends StatefulWidget {
  const BrockmannPivot({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  }) : assert(selected >= 0),
       assert(options.length == 0 || selected < options.length);
  final List<String> options;
  final int selected;
  final ValueChanged<int>? onChanged;
  final bool compact;
  @override
  State<BrockmannPivot> createState() => _BrockmannPivotState();
}

class _BrockmannPivotState extends State<BrockmannPivot> {
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  List<GlobalKey> _keys = [];
  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant BrockmannPivot old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected || old.options != widget.options) {
      _schedule();
    }
  }

  void _schedule() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted ||
        widget.options.isEmpty ||
        !_scroll.hasClients ||
        widget.selected >= _keys.length) {
      return;
    }
    final box =
        _keys[widget.selected].currentContext?.findRenderObject() as RenderBox?;
    final viewport = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || viewport == null) return;
    final x = box.localToGlobal(Offset.zero, ancestor: viewport).dx;
    final current = _scroll.offset;
    final delta = x < 0
        ? x
        : x + box.size.width > viewport.size.width
        ? x + box.size.width - viewport.size.width
        : 0.0;
    final target = (current + delta).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if ((target - current).abs() < .5) return;
    final t = context.brockmann;
    if (t.motionReduced(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: t.duration(context, 180),
        curve: brockmannEaseOut,
      );
    }
  });
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.brockmann;
    if (_keys.length != widget.options.length) {
      _keys = List.generate(widget.options.length, (_) => GlobalKey());
    }
    final role = widget.compact ? BrockmannType.body : BrockmannType.title;
    final sizes = widget.options.map((label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: role.style()),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      return Size(
        math.max(48, painter.width),
        math.max(48, painter.height + 20),
      );
    }).toList();
    final height = sizes.fold(48.0, (h, s) => math.max(h, s.height));
    final offset = sizes
        .take(widget.selected)
        .fold(0.0, (x, s) => x + s.width + 24);
    return SizedBox(
      key: _viewport,
      height: height,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.options.length; i++)
                  Padding(
                    key: _keys[i],
                    padding: EdgeInsets.only(
                      right: i == widget.options.length - 1 ? 0 : 24,
                    ),
                    child: SizedBox(
                      width: sizes[i].width,
                      height: height,
                      child: BrockmannPressable(
                        label: widget.options[i],
                        selected: widget.selected == i,
                        onKey: widget.onChanged == null
                            ? null
                            : (key) {
                                final next = key == LogicalKeyboardKey.home
                                    ? 0
                                    : key == LogicalKeyboardKey.end
                                    ? widget.options.length - 1
                                    : (widget.selected +
                                              (key ==
                                                          LogicalKeyboardKey
                                                              .arrowLeft ||
                                                      key ==
                                                          LogicalKeyboardKey
                                                              .arrowUp
                                                  ? -1
                                                  : 1))
                                          .clamp(0, widget.options.length - 1);
                                if (next != widget.selected) {
                                  BrockmannFeedbackScope.play(
                                    context,
                                    BrockmannSound.select,
                                  );
                                  widget.onChanged!(next);
                                }
                              },
                        onPressed: widget.onChanged == null
                            ? null
                            : () {
                                if (i != widget.selected) {
                                  BrockmannFeedbackScope.play(
                                    context,
                                    BrockmannSound.select,
                                  );
                                  widget.onChanged!(i);
                                }
                              },
                        builder: (c, p) => Align(
                          alignment: Alignment.centerLeft,
                          child: BrockmannText(
                            widget.options[i],
                            role: role,
                            color: widget.onChanged == null
                                ? t.disabled
                                : i == widget.selected
                                ? t.foreground
                                : widget.compact
                                ? t.secondary
                                : t.disabled,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.compact && widget.options.isNotEmpty)
              AnimatedPositioned(
                duration: t.duration(context, 180),
                curve: brockmannEaseOut,
                left: offset,
                bottom: 0,
                width: sizes[widget.selected].width,
                height: 2,
                child: ColoredBox(
                  color: widget.onChanged == null ? t.disabled : t.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BrockmannPicker extends StatelessWidget {
  const BrockmannPicker({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  }) : assert(selected >= 0),
       assert(options.length == 0 || selected < options.length);
  final String label;
  final List<String> options;
  final int selected;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = context.brockmann;
    final enabled = onChanged != null && options.isNotEmpty;
    return Builder(
      builder: (anchorContext) => BrockmannPressable(
        label: '$label, ${options.isEmpty ? 'No options' : options[selected]}',
        onPressed: !enabled
            ? null
            : () async {
                final box = anchorContext.findRenderObject()! as RenderBox;
                final rect = box.localToGlobal(Offset.zero) & box.size;
                final feedback = BrockmannFeedbackScope.of(context);
                feedback?.play(BrockmannSound.open);
                final result = await Navigator.of(context).push<int>(
                  _PickerRoute(
                    label: label,
                    options: List.of(options),
                    selected: selected,
                    anchor: rect,
                    theme: t.copyWith(reduceMotion: t.motionReduced(context)),
                  ),
                );
                if (!context.mounted) return;
                if (result != null && result != selected) {
                  feedback?.play(BrockmannSound.select);
                  onChanged?.call(result);
                } else {
                  feedback?.play(BrockmannSound.close);
                }
              },
        builder: (c, p) => Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: p ? t.foreground : t.lineStrong,
              width: p ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrockmannText(
                label,
                role: BrockmannType.label,
                color: enabled ? t.secondary : t.disabled,
              ),
              const SizedBox(height: 4),
              BrockmannText(
                options.isEmpty ? 'No options' : options[selected],
                role: BrockmannType.value,
                color: enabled ? t.foreground : t.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRoute extends PopupRoute<int> {
  _PickerRoute({
    required this.label,
    required this.options,
    required this.selected,
    required this.anchor,
    required this.theme,
  });
  final String label;
  final List<String> options;
  final int selected;
  final Rect anchor;
  final BrockmannThemeData theme;
  @override
  Color get barrierColor =>
      Colors.black.withValues(alpha: theme.light ? .4 : .6);
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => 'Close $label';
  @override
  Duration get transitionDuration => Duration(
    milliseconds: (theme.reduceMotion ? 100 : 440 * theme.motionScale).round(),
  );
  @override
  Duration get reverseTransitionDuration => Duration(
    milliseconds: (theme.reduceMotion ? 100 : 200 * theme.motionScale).round(),
  );
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final media = MediaQuery.of(context);
    final full = media.size.width < 720 || media.textScaler.scale(16) > 24;
    final t = context.brockmann;
    final rowHeight = math.max(56.0, media.textScaler.scale(24) + 24);
    final top = media.padding.top + 16,
        bottom = media.size.height - media.padding.bottom - 16;
    final height = math.min(rowHeight * options.length + 16, bottom - top);
    final width = math.min(
      math.max(anchor.width, 280.0),
      media.size.width - 48,
    );
    final x = anchor.left.clamp(
      24.0,
      math.max(24, media.size.width - width - 24),
    );
    final y =
        (anchor.top +
                32 -
                (rowHeight - media.textScaler.scale(24)) / 2 -
                selected * rowHeight -
                8)
            .clamp(top, math.max(top, bottom - height));
    final list = _PickerList(
      label: label,
      options: options,
      selected: selected,
      rowHeight: rowHeight,
      fullPage: full,
      animation: animation,
    );
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: label,
      child: full
          ? ColoredBox(
              color: t.background,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          BrockmannIconButton(
                            icon: BrockmannIcon.arrowLeft,
                            label: 'Close $label',
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BrockmannText(
                              label,
                              role: BrockmannType.heading,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: list),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Positioned(
                  left: x.toDouble(),
                  top: y.toDouble(),
                  width: width,
                  height: height,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (c, _) {
                      final opening =
                          animation.status != AnimationStatus.reverse;
                      final progress = t.motionReduced(c)
                          ? 1.0
                          : brockmannOutExpo.transform(
                              (animation.value * (opening ? 2 : 1)).clamp(0, 1),
                            );
                      final rowTop = (8 + selected * rowHeight).clamp(
                        0.0,
                        math.max(0.0, height - rowHeight),
                      );
                      final reveal = Rect.lerp(
                        Rect.fromLTWH(
                          0,
                          rowTop.toDouble(),
                          width,
                          math.min(height, rowHeight + 16),
                        ),
                        Rect.fromLTWH(0, 0, width, height),
                        progress,
                      )!;
                      return ClipRect(
                        clipper: _PickerClip(reveal),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.surface,
                            border: Border.all(color: t.line, width: 0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: list,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final media = MediaQuery.of(context);
    if (media.size.width >= 720 && media.textScaler.scale(16) <= 24) {
      return child;
    }
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (c, child) {
        final exiting = animation.status == AnimationStatus.reverse;
        final reduced = c.brockmann.motionReduced(c);
        final f = exiting
            ? 1 - brockmannInExpo.transform(1 - animation.value)
            : brockmannOutExpo.transform((animation.value * 2).clamp(0, 1));
        return Opacity(
          opacity: f,
          child: Transform.translate(
            offset: Offset(0, reduced ? 0 : 24 * (1 - f)),
            child: child,
          ),
        );
      },
    );
  }
}

class _PickerList extends StatefulWidget {
  const _PickerList({
    required this.label,
    required this.options,
    required this.selected,
    required this.rowHeight,
    required this.fullPage,
    required this.animation,
  });
  final String label;
  final List<String> options;
  final int selected;
  final double rowHeight;
  final bool fullPage;
  final Animation<double> animation;
  @override
  State<_PickerList> createState() => _PickerListState();
}

class _PickerListState extends State<_PickerList> {
  late final _scroll = ScrollController(
    initialScrollOffset: widget.fullPage
        ? widget.selected * widget.rowHeight
        : 0,
  );
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    controller: _scroll,
    padding: EdgeInsets.symmetric(
      horizontal: widget.fullPage ? 24 : 0,
      vertical: widget.fullPage ? 16 : 0,
    ),
    itemCount: widget.options.length,
    itemBuilder: (c, i) => AnimatedBuilder(
      animation: widget.animation,
      builder: (c, _) {
        final f =
            !widget.fullPage ||
                c.brockmann.motionReduced(c) ||
                widget.animation.status == AnimationStatus.reverse
            ? 1.0
            : brockmannOutExpo.transform(
                ((widget.animation.value * .44 - math.min(i, 7) * .03) / .22)
                    .clamp(0, 1),
              );
        return Opacity(
          opacity: f,
          child: Transform.translate(
            offset: Offset(-40 * (1 - f), 0),
            child: BrockmannPressable(
              label: widget.options[i],
              selected: i == widget.selected,
              onPressed: () => Navigator.pop(context, i),
              builder: (c, p) => Container(
                constraints: BoxConstraints(minHeight: widget.rowHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: p ? c.brockmann.line.withValues(alpha: .3) : null,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BrockmannText(
                    widget.options[i],
                    role: BrockmannType.value,
                    color: i == widget.selected
                        ? c.brockmann.accentText
                        : c.brockmann.foreground,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _PickerClip extends CustomClipper<Rect> {
  const _PickerClip(this.rect);
  final Rect rect;
  @override
  Rect getClip(Size size) => rect;
  @override
  bool shouldReclip(_PickerClip old) => old.rect != rect;
}
