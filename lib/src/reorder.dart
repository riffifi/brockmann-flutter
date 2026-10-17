import 'package:flutter/semantics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'theme.dart';
import 'feedback.dart';

/// Stable keyed children, flat drag proxy, automatic edge scroll and neighbour motion.
/// `newIndex` is already adjusted for removal (Flutter 3.47 onReorderItem API).
class BrockmannReorderableList extends StatelessWidget {
  const BrockmannReorderableList({
    super.key,
    required this.children,
    required this.onReorder,
    this.shrinkWrap = false,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.axis = Axis.vertical,
    this.physics,
    this.header,
  });
  final List<Widget> children;
  final void Function(int oldIndex, int newIndex) onReorder;
  final bool shrinkWrap;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;
  final Axis axis;
  final ScrollPhysics? physics;
  final Widget? header;
  @override
  Widget build(BuildContext context) {
    assert(
      children.every((c) => c.key != null),
      'Reorderable children need stable identity keys.',
    );
    final t = context.brockmann;
    return ReorderableListView.builder(
      header: header,
      buildDefaultDragHandles: false,
      itemCount: children.length,
      onReorderItem: onReorder,
      onReorderStart: (_) =>
          BrockmannFeedbackScope.of(context)?.gesture(lifting: true),
      onReorderEnd: (_) =>
          BrockmannFeedbackScope.of(context)?.gesture(lifting: false),
      scrollController: controller,
      shrinkWrap: shrinkWrap,
      padding: padding.resolve(Directionality.of(context)),
      scrollDirection: axis,
      physics: physics ?? const ClampingScrollPhysics(),
      proxyDecorator: (child, index, animation) => DecoratedBox(
        decoration: BoxDecoration(
          color: t.background,
          border: Border.all(color: t.lineStrong),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            extensions: [
              ...Theme.of(context).extensions.values
                  .where((e) => e is! BrockmannThemeData),
              t.copyWith(tilt: false),
            ],
          ),
          child: child,
        ),
      ),
      itemBuilder: (c, i) => Semantics(
        key: children[i].key,
        customSemanticsActions: {
          if (i > 0)
            const CustomSemanticsAction(label: 'Move earlier'): () =>
                onReorder(i, i - 1),
          if (i + 1 < children.length)
            const CustomSemanticsAction(label: 'Move later'): () =>
                onReorder(i, i + 1),
        },
        child: _TouchReorderListener(index: i, child: children[i]),
      ),
    );
  }
}

class _TouchReorderListener extends ReorderableDragStartListener {
  const _TouchReorderListener({required super.index, required super.child});
  @override
  MultiDragGestureRecognizer createRecognizer() =>
      DelayedMultiDragGestureRecognizer(
        delay: const Duration(milliseconds: 250),
        debugOwner: this,
      );
}
