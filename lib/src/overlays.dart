import 'package:flutter/material.dart';

import 'theme.dart';
import 'foundation.dart';
import 'pickers.dart';
import 'controls.dart';
import 'feedback.dart';

/// Flat modal with wrapped, touch-sized text actions. Android back dismisses it.
Future<String?> showBrockmannDialog(
  BuildContext context, {
  required String title,
  required String message,
  List<String> actions = const ['close'],
}) async {
  final feedback = BrockmannFeedbackScope.of(context);
  feedback?.play(BrockmannSound.open);
  final result = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close $title',
    barrierColor: Colors.black.withValues(
      alpha: context.brockmann.light ? .4 : .6,
    ),
    transitionDuration: context.brockmann.duration(context, 160),
    pageBuilder: (c, _, _) => _FlatDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            namesRoute: true,
            child: BrockmannText(title, role: BrockmannType.heading),
          ),
          const SizedBox(height: 16),
          BrockmannText(message),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (var i = 0; i < actions.length; i++)
                BrockmannButton(
                  label: actions[i],
                  style: i == 0
                      ? BrockmannButtonStyle.primary
                      : BrockmannButtonStyle.text,
                  onPressed: () => Navigator.pop(c, actions[i]),
                ),
            ],
          ),
        ],
      ),
    ),
    transitionBuilder: (c, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  );
  feedback?.play(BrockmannSound.close);
  return result;
}

class _FlatDialog extends StatelessWidget {
  const _FlatDialog({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = context.brockmann;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Center(
        child: Material(
          color: t.surface,
          shape: Border.symmetric(
            horizontal: BorderSide(color: t.line, width: 0),
          ),
          child: SizedBox(
            width: double.infinity,
            child: SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showBrockmannToast(BuildContext context, String message) {
  final t = context.brockmann;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: BrockmannText(message),
        backgroundColor: t.surface,
        elevation: 0,
        shape: Border(top: BorderSide(color: t.line)),
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(milliseconds: 2800),
      ),
    );
}

Future<String?> showBrockmannMenu(
  BuildContext context, {
  required String label,
  required List<String> actions,
}) async {
  BrockmannFeedbackScope.play(context, BrockmannSound.open);
  final result = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close $label',
    transitionDuration: context.brockmann.duration(context, 160),
    pageBuilder: (c, _, _) => _FlatDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrockmannText(
            label,
            role: BrockmannType.label,
            color: c.brockmann.secondary,
          ),
          const SizedBox(height: 12),
          for (final action in actions)
            BrockmannButton(
              label: action,
              style: BrockmannButtonStyle.text,
              onPressed: () => Navigator.pop(c, action),
            ),
        ],
      ),
    ),
    transitionBuilder: (c, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  );
  if (context.mounted) {
    BrockmannFeedbackScope.play(context, BrockmannSound.close);
  }
  return result;
}

Future<String?> showBrockmannCommands(
  BuildContext context,
  List<String> commands,
) async {
  BrockmannFeedbackScope.play(context, BrockmannSound.open);
  final result = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close commands',
    transitionDuration: context.brockmann.duration(context, 160),
    pageBuilder: (c, _, _) => _CommandDialog(commands: commands),
    transitionBuilder: (c, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  );
  if (context.mounted) {
    BrockmannFeedbackScope.play(context, BrockmannSound.close);
  }
  return result;
}

class _CommandDialog extends StatefulWidget {
  const _CommandDialog({required this.commands});
  final List<String> commands;
  @override
  State<_CommandDialog> createState() => _CommandDialogState();
}

class _CommandDialogState extends State<_CommandDialog> {
  final _query = TextEditingController();
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.commands
        .where((c) => c.toLowerCase().contains(_query.text.toLowerCase()))
        .toList();
    return _FlatDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrockmannTextField(
            label: 'Find a command',
            controller: _query,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (matches.isEmpty) const BrockmannText('No matching commands'),
          for (final command in matches.take(12))
            BrockmannButton(
              label: command,
              style: BrockmannButtonStyle.text,
              onPressed: () => Navigator.pop(context, command),
            ),
        ],
      ),
    );
  }
}

/// One typed menu definition can be used by a context menu or action sheet.
@immutable
class BrockmannMenuEntry<T> {
  const BrockmannMenuEntry({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.destructive = false,
  });
  final T value;
  final String label;
  final BrockmannIcon? icon;
  final bool enabled, destructive;
}

Future<T?> showBrockmannContextMenu<T>(
  BuildContext context, {
  required Offset position,
  required List<BrockmannMenuEntry<T>> entries,
  bool showIcons = false,
}) {
  final t = context.brockmann;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
  final local = overlay.globalToLocal(position);
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromRect(
      local & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    color: t.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: Border.all(color: t.line),
    menuPadding: const EdgeInsets.symmetric(vertical: 8),
    items: [
      for (final entry in entries)
        PopupMenuItem<T>(
          value: entry.value,
          enabled: entry.enabled,
          height: 48,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcons && entry.icon != null) ...[
                BrockmannGlyph(
                  entry.icon!,
                  color: entry.destructive ? t.danger : t.secondary,
                ),
                const SizedBox(width: 16),
              ],
              Flexible(
                child: BrockmannText(
                  entry.label,
                  color: !entry.enabled
                      ? t.disabled
                      : entry.destructive
                      ? t.danger
                      : t.foreground,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class BrockmannContextMenu<T> extends StatelessWidget {
  const BrockmannContextMenu({
    super.key,
    required this.entries,
    required this.onSelected,
    required this.child,
  });
  final List<BrockmannMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    Future<void> open(Offset p) async {
      final result = await showBrockmannContextMenu(
        context,
        position: p,
        entries: entries,
      );
      if (result != null && context.mounted) onSelected(result);
    }

    return GestureDetector(
      onLongPressStart: (d) => open(d.globalPosition),
      onSecondaryTapDown: (d) => open(d.globalPosition),
      child: child,
    );
  }
}

Future<T?> showBrockmannActionSheet<T>(
  BuildContext context, {
  required String title,
  required List<BrockmannMenuEntry<T>> entries,
  bool showIcons = false,
}) {
  final t = context.brockmann;
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: t.surface,
    elevation: 0,
    shape: Border(top: BorderSide(color: t.line)),
    builder: (c) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * .8),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BrockmannText(title, role: BrockmannType.heading),
              const SizedBox(height: 16),
              for (final entry in entries)
                BrockmannPressable(
                  label: entry.label,
                  onPressed: entry.enabled
                      ? () => Navigator.pop(c, entry.value)
                      : null,
                  builder: (c, p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        if (showIcons && entry.icon != null) ...[
                          BrockmannGlyph(
                            entry.icon!,
                            color: entry.destructive ? t.danger : t.secondary,
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: BrockmannText(
                            entry.label,
                            color: !entry.enabled
                                ? t.disabled
                                : entry.destructive
                                ? t.danger
                                : t.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<DateTime?> showBrockmannDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final first = DateUtils.dateOnly(firstDate),
      last = DateUtils.dateOnly(lastDate);
  var draft = DateUtils.dateOnly(initialDate);
  assert(
    !last.isBefore(first) && !draft.isBefore(first) && !draft.isAfter(last),
  );
  return _showTypedPicker<DateTime>(
    context,
    'choose date',
    (c, set) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrockmannText('choose date', role: BrockmannType.heading),
        const SizedBox(height: 16),
        BrockmannCalendar(
          value: draft,
          firstDate: first,
          lastDate: last,
          onChanged: (v) => set(() => draft = v),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            BrockmannButton(
              label: 'use date',
              style: BrockmannButtonStyle.secondary,
              onPressed: () => Navigator.pop(c, draft),
            ),
            BrockmannButton(
              label: 'cancel',
              style: BrockmannButtonStyle.text,
              onPressed: () => Navigator.pop(c),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<TimeOfDay?> showBrockmannTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  var draft = initialTime;
  return _showTypedPicker<TimeOfDay>(
    context,
    'choose time',
    (c, set) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrockmannText('choose time', role: BrockmannType.heading),
        const SizedBox(height: 16),
        BrockmannTimePicker(
          value: draft,
          onChanged: (v) => set(() => draft = v),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            BrockmannButton(
              label: 'use time',
              style: BrockmannButtonStyle.secondary,
              onPressed: () => Navigator.pop(c, draft),
            ),
            BrockmannButton(
              label: 'cancel',
              style: BrockmannButtonStyle.text,
              onPressed: () => Navigator.pop(c),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<T?> _showTypedPicker<T>(
  BuildContext context,
  String title,
  Widget Function(BuildContext, StateSetter) content,
) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close $title',
  barrierColor: Colors.black.withValues(
    alpha: context.brockmann.light ? .4 : .6,
  ),
  transitionDuration: context.brockmann.duration(context, 220),
  pageBuilder: (c, _, _) =>
      StatefulBuilder(builder: (c, set) => _FlatDialog(child: content(c, set))),
  transitionBuilder: (c, a, _, child) =>
      FadeTransition(opacity: a, child: child),
);
