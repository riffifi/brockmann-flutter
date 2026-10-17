import 'package:flutter/material.dart';

import 'theme.dart';
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
