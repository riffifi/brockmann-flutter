import 'dart:async';

import 'package:flutter/material.dart';
import 'package:brockmann/brockmann.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Showcase(preferences: await BrockmannPreferences.read()));
}

class Showcase extends StatefulWidget {
  const Showcase({super.key, this.preferences = const {}});
  final Map<String, dynamic> preferences;
  @override
  State<Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase> {
  late final sound = BrockmannFeedbackController();
  late bool light = widget.preferences['light'] as bool? ?? false;
  late bool reduced = widget.preferences['reduced'] as bool? ?? false;
  late Color accent = Color(widget.preferences['accent'] as int? ?? 0xff00aba9);
  Timer? saveTimer;
  bool slow = false;
  @override
  void initState() {
    super.initState();
    final mode = widget.preferences['sound'] as String? ?? 'off';
    unawaited(
      sound.configure(
        mode: BrockmannSoundMode.values.firstWhere(
          (m) => m.name == mode,
          orElse: () => BrockmannSoundMode.off,
        ),
        haptics: BrockmannHapticMode.values.firstWhere(
          (m) =>
              m.name ==
              (widget.preferences['haptics'] as String? ?? 'essential'),
          orElse: () => BrockmannHapticMode.essential,
        ),
        volume: (widget.preferences['volume'] as num?)?.toDouble() ?? .35,
      ),
    );
  }

  void save() {
    saveTimer?.cancel();
    saveTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(
        BrockmannPreferences.write({
          'light': light,
          'reduced': reduced,
          'accent': accent.toARGB32(),
          'sound': sound.mode.name,
          'haptics': sound.hapticMode.name,
          'volume': sound.volume,
        }),
      );
    });
  }

  @override
  void dispose() {
    saveTimer?.cancel();
    sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BrockmannApp(
    theme: BrockmannThemeData(
      brightness: light ? Brightness.light : Brightness.dark,
      accent: accent,
      reduceMotion: reduced,
      motionScale: slow ? 10 : 1,
    ),
    feedback: sound,
    home: Catalogue(
      sound: sound,
      light: light,
      reduced: reduced,
      slow: slow,
      onLight: () {
        setState(() => light = !light);
        save();
      },
      onReduced: (v) {
        setState(() => reduced = v);
        save();
      },
      onSlow: (v) => setState(() => slow = v),
      onAccent: (v) {
        setState(() => accent = v);
        save();
      },
      onSound: save,
    ),
  );
}

const pages = [
  'colour',
  'controls',
  'typography',
  'tiles',
  'overlays',
  'motion',
  'layout',
  'sound',
  'inputs',
  'pickers',
  'icons',
];

class Catalogue extends StatefulWidget {
  const Catalogue({
    super.key,
    required this.sound,
    required this.light,
    required this.reduced,
    required this.slow,
    required this.onLight,
    required this.onReduced,
    required this.onSlow,
    required this.onAccent,
    required this.onSound,
  });
  final BrockmannSoundController sound;
  final bool light, reduced, slow;
  final VoidCallback onLight, onSound;
  final ValueChanged<bool> onReduced, onSlow;
  final ValueChanged<Color> onAccent;
  @override
  State<Catalogue> createState() => _CatalogueState();
}

class _CatalogueState extends State<Catalogue> {
  int page = 0, choice = 0, color = 11, companions = 0, variant = 2;
  bool enabled = true, vertical = false, busy = false;
  double amount = .64, tone = .4, weight = 400;
  final schemes = brockmannPalette();
  Color customColour = const Color(0xff39a6a0);
  bool? checked = true;
  bool expanded = false;
  String segment = 'week', quality = 'balanced';
  RangeValues range = const RangeValues(.2, .75);
  double quantity = 4;
  DateTime date = DateTime(2026, 10, 18);
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 30);
  final search = TextEditingController();
  final sessionActions = const [
    BrockmannMenuEntry(
      value: 'rename',
      label: 'Rename',
      icon: BrockmannIcon.pencil,
    ),
    BrockmannMenuEntry(
      value: 'duplicate',
      label: 'Duplicate',
      icon: BrockmannIcon.copy,
    ),
    BrockmannMenuEntry(
      value: 'delete',
      label: 'Delete',
      icon: BrockmannIcon.trash,
      destructive: true,
    ),
  ];
  final projectName = TextEditingController(text: 'untitled session');
  final notes = TextEditingController(
    text: 'Space is structure.\nWrite in your own language.',
  );
  final validation = TextEditingController(text: '0');
  @override
  void dispose() {
    search.dispose();
    projectName.dispose();
    notes.dispose();
    validation.dispose();
    super.dispose();
  }

  final order = [
    'kick',
    'snare',
    'closed hat',
    'open hat',
    'clap',
    'rim',
    'tom',
    'ride',
  ];
  @override
  void initState() {
    super.initState();
    const initial = String.fromEnvironment(
      'BROCKMANN_PAGE',
      defaultValue: 'controls',
    );
    page = pages.indexOf(initial).clamp(0, pages.length - 1);
  }

  Widget section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      BrockmannFeather(
        index: 0,
        child: BrockmannText(title, role: BrockmannType.heading),
      ),
      const SizedBox(height: 24),
      for (var i = 0; i < children.length; i++) ...[
        BrockmannFeather(index: i + 1, child: children[i]),
        const SizedBox(height: 24),
      ],
    ],
  );
  Widget note(String text) =>
      BrockmannText(text, color: context.brockmann.secondary);
  Widget buttons(List<Widget> children) =>
      Wrap(spacing: 16, runSpacing: 12, children: children);
  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Expanded(
                  child: BrockmannText(
                    'BROCKMANN / COMPONENT LIBRARY',
                    role: BrockmannType.label,
                  ),
                ),
                BrockmannButton(
                  label: widget.light ? 'dark' : 'light',
                  style: BrockmannButtonStyle.text,
                  onPressed: widget.onLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BrockmannPivot(
            options: pages,
            selected: page,
            onChanged: (v) => setState(() => page = v),
            compact: false,
          ),
        ],
      ),
    );
    return BrockmannPage(
      header: header,
      scroll: false,
      padding: EdgeInsets.zero,
      child: BrockmannPageSwitcher(
        selected: page,
        pageCount: pages.length,
        onChanged: (v) => setState(() => page = v),
        child: page == 3
            ? Padding(
                key: ValueKey(page),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: content(context),
              )
            : SingleChildScrollView(
                key: PageStorageKey(page),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: content(context),
              ),
      ),
    );
  }

  Widget content(BuildContext context) => switch (page) {
    1 => section('controls', [
      note(
        'Direct, quiet controls. Every action has at least 48 dp of touch space.',
      ),
      buttons([
        BrockmannButton(
          label: 'primary',
          style: BrockmannButtonStyle.primary,
          onPressed: () => showBrockmannToast(context, 'Action completed'),
        ),
        BrockmannButton(label: 'secondary', onPressed: () {}),
        BrockmannButton(
          label: 'text action',
          style: BrockmannButtonStyle.text,
          onPressed: () {},
        ),
        const BrockmannButton(label: 'disabled'),
      ]),
      BrockmannSwitch(
        label: 'enable processing',
        value: enabled,
        onChanged: (v) => setState(() => enabled = v),
      ),
      const BrockmannSwitch(label: 'unavailable', value: false),
      BrockmannSlider(
        label: 'amount',
        value: amount,
        defaultValue: .5,
        formatValue: (v) => '${(v * 100).round()}%',
        onChanged: (v) => setState(() => amount = v),
      ),
      buttons([
        BrockmannKnob(
          label: 'tone',
          value: tone,
          defaultValue: .5,
          onChanged: (v) => setState(() => tone = v),
        ),
        const BrockmannKnob(label: 'disabled', value: .3, onChanged: null),
      ]),
      BrockmannPicker(
        label: 'instrument',
        options: order,
        selected: choice,
        onChanged: (v) => setState(() => choice = v),
      ),
      BrockmannTextField(label: 'project name', controller: projectName),
      BrockmannTextField(label: 'notes', multiline: true, controller: notes),
      BrockmannTextField(
        label: 'validation',
        controller: validation,
        error: 'Enter a value greater than zero.',
      ),
      buttons([
        for (final icon in BrockmannIcon.values)
          BrockmannIconButton(icon: icon, label: icon.name, onPressed: () {}),
      ]),
    ]),
    0 => section('colour as material', [
      note(
        'A palette of deliberate choices, or a continuous colour field. Selection expands the tile and adds a contrast-safe check. Continuous controls follow touch immediately.',
      ),
      BrockmannSegmentedControl<int>(
        options: const [2, 1],
        value: variant,
        onChanged: (v) => setState(() => variant = v),
        labelFor: (v) => v == 2 ? 'tiles' : 'strip',
      ),
      BrockmannColorPicker(
        label: 'palette',
        schemes: schemes,
        selected: color,
        onChanged: (v) => setState(() => color = v),
        variant: BrockmannPaletteVariant.values[variant],
      ),
      BrockmannButton(
        label: 'use ${schemes[color].name}',
        onPressed: () => widget.onAccent(schemes[color].primary),
      ),
      BrockmannColorField(
        label: 'compose a colour',
        value: customColour,
        showAlpha: true,
        onChanged: (v) => setState(() => customColour = v),
      ),
      BrockmannButton(
        label: 'use composed colour',
        onPressed: () => widget.onAccent(customColour.withValues(alpha: 1)),
      ),
    ]),
    2 => section('type is the interface', [
      note(
        'Geist Sans for hierarchy, Geist Mono for values. Pixel cuts are expressive accents, used sparingly.',
      ),
      for (final role in BrockmannType.values)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrockmannText(
              role.name,
              role: BrockmannType.label,
              color: context.brockmann.secondary,
            ),
            const SizedBox(height: 8),
            BrockmannText(
              role.name.startsWith('pixel') ? 'Aa 012' : 'space is structure',
              role: role,
            ),
          ],
        ),
      BrockmannSlider(
        label: 'variable weight',
        value: weight,
        min: 100,
        max: 900,
        step: 1,
        onChanged: (v) => setState(() => weight = v),
      ),
      BrockmannMotion(
        value: weight,
        milliseconds: 800,
        curve: brockmannInOut,
        builder: (c, animatedWeight) => Text(
          'Aa 012345',
          style: TextStyle(
            fontFamily: 'Geist',
            package: 'brockmann',
            fontSize: 40,
            fontVariations: [FontVariation('wght', animatedWeight)],
          ),
        ),
      ),
      buttons([
        BrockmannButton(
          label: 'animate to 200',
          onPressed: () => setState(() => weight = 200),
        ),
        BrockmannButton(
          label: 'animate to 800',
          onPressed: () => setState(() => weight = 800),
        ),
      ]),
    ]),
    3 => BrockmannReorderableList(
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrockmannText('hold, then move', role: BrockmannType.heading),
            const SizedBox(height: 12),
            note(
              'Hold a tile for 250 ms. Neighbours make room as you move. TalkBack offers Move earlier / later.',
            ),
          ],
        ),
      ),
      onReorder: (a, b) => setState(() => order.insert(b, order.removeAt(a))),
      children: [
        for (var i = 0; i < order.length; i++)
          Padding(
            key: ValueKey(order[i]),
            padding: const EdgeInsets.only(bottom: 12),
            child: BrockmannFeather(
              index: i + 1,
              child: BrockmannTile(
                label: order[i],
                value: '${i + 1}'.padLeft(2, '0'),
                active: i == 0,
                onPressed: () {},
              ),
            ),
          ),
      ],
    ),
    4 => section('a moment of focus', [
      note(
        'On phones, lists open as a full page with the current selection in view. Back closes without changing the value.',
      ),
      BrockmannPicker(
        label: 'destination',
        options: const ['studio', 'library', 'settings', 'about'],
        selected: choice.clamp(0, 3),
        onChanged: (v) => setState(() => choice = v),
      ),
      BrockmannButton(
        label: 'open dialog',
        onPressed: () => showBrockmannDialog(
          context,
          title: 'Keep this session?',
          message: 'The surrounding space dims. The choice stays clear.',
          actions: const ['keep', 'cancel'],
        ),
      ),
      BrockmannButton(
        label: 'open menu',
        onPressed: () async {
          final selected = await showBrockmannMenu(
            context,
            label: 'session',
            actions: const ['rename', 'duplicate'],
          );
          if (context.mounted && selected != null) {
            showBrockmannToast(context, '$selected selected');
          }
        },
      ),
      BrockmannButton(
        label: 'find a command',
        onPressed: () async {
          final selected = await showBrockmannCommands(context, const [
            'New session',
            'Open library',
            'Toggle theme',
          ]);
          if (!context.mounted || selected == null) return;
          if (selected == 'Toggle theme') {
            widget.onLight();
          } else if (selected == 'Open library') {
            setState(() => page = 3);
          } else {
            showBrockmannToast(context, 'New session');
          }
        },
      ),
      BrockmannButton(
        label: 'show toast',
        onPressed: () => showBrockmannToast(context, 'Saved locally'),
      ),
    ]),
    5 => section('motion with purpose', [
      note(
        'Motion explains a state change. The system’s Reduce animations setting is always respected.',
      ),
      BrockmannSwitch(
        label: 'reduce motion',
        value: widget.reduced,
        onChanged: widget.onReduced,
      ),
      BrockmannSwitch(
        label: 'slow motion study',
        value: widget.slow,
        onChanged: widget.onSlow,
      ),
      BrockmannSwitch(
        label: 'symmetric switch',
        value: enabled,
        onChanged: (v) => setState(() => enabled = v),
      ),
      BrockmannSlider(
        label: 'progress',
        value: amount,
        onChanged: (v) => setState(() => amount = v),
      ),
      buttons([
        BrockmannButton(
          label: 'set 15%',
          onPressed: () => setState(() => amount = .15),
        ),
        BrockmannButton(
          label: 'set 85%',
          onPressed: () => setState(() => amount = .85),
        ),
      ]),
      BrockmannProgress(label: 'upload', value: amount),
      BrockmannSwitch(
        label: 'indeterminate activity',
        value: busy,
        onChanged: (v) => setState(() => busy = v),
      ),
      if (busy) const BrockmannProgress(label: 'working'),
      BrockmannLiveTile(
        label: 'live tile',
        primary: '96',
        secondary: '120',
        onPressed: () {},
      ),
    ]),
    6 => section('space is structure', [
      note(
        'An 8 dp rhythm. Labels and values occupy separate lines; content grows with the user’s text size.',
      ),
      buttons([
        BrockmannTile(
          label: 'one unit',
          value: '96',
          width: 128,
          active: true,
          onPressed: () {},
        ),
        BrockmannTile(
          label: 'two units',
          value: '200',
          width: 200,
          onPressed: () {},
        ),
      ]),
      BrockmannListItem(
        label: 'selected item',
        secondary: 'An inset selection marker with room to breathe.',
        selected: true,
        onPressed: () {},
      ),
      BrockmannListItem(
        label: 'another item',
        secondary: 'Secondary text wraps naturally.',
        onPressed: () {},
      ),
      BrockmannMeter(label: 'output / dB', db: amount * 60 - 60),
      BrockmannSlider(
        label: 'signal level',
        value: amount,
        onChanged: (v) => setState(() => amount = v),
      ),
      const BrockmannMeter(
        label: 'vertical / dB',
        db: -12,
        axis: Axis.vertical,
      ),
    ]),
    8 => section('inputs for real applications', [
      BrockmannSearchField(controller: search, label: 'search instruments'),
      BrockmannCheckbox(
        label: 'include automation',
        value: checked,
        tristate: true,
        onChanged: (v) => setState(() => checked = v),
      ),
      BrockmannRadioGroup<String>(
        label: 'render quality',
        options: const ['draft', 'balanced', 'master'],
        value: quality,
        onChanged: (v) => setState(() => quality = v),
        labelFor: (v) => v,
      ),
      BrockmannSegmentedControl<String>(
        options: const ['day', 'week', 'month'],
        value: segment,
        onChanged: (v) => setState(() => segment = v),
        labelFor: (v) => v,
      ),
      BrockmannRangeSlider(
        label: 'play region',
        values: range,
        onChanged: (v) => setState(() => range = v),
      ),
      BrockmannStepper(
        label: 'voices',
        value: quantity,
        min: 1,
        max: 16,
        onChanged: (v) => setState(() => quantity = v),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          BrockmannChip(
            label: 'synth',
            selected: checked == true,
            onPressed: () => setState(() => checked = checked != true),
          ),
          BrockmannChip(
            label: 'removable',
            onDeleted: () => showBrockmannToast(context, 'Tag removed'),
          ),
          const BrockmannBadge(label: 'local'),
        ],
      ),
      BrockmannAccordion(
        title: 'Advanced settings',
        expanded: expanded,
        onChanged: (v) => setState(() => expanded = v),
        child: note(
          'Keep secondary settings nearby without overwhelming the primary workflow.',
        ),
      ),
      BrockmannBanner(
        title: 'Project saved',
        message: 'All changes are stored on this device.',
        icon: BrockmannIcon.check,
      ),
      const BrockmannEmptyState(
        title: 'Nothing queued',
        message: 'Add an instrument to start building.',
        icon: BrockmannIcon.folder,
      ),
      BrockmannNavigationBar(
        destinations: const [
          BrockmannDestination('studio', BrockmannIcon.settings),
          BrockmannDestination('library', BrockmannIcon.folder),
          BrockmannDestination('account', BrockmannIcon.user),
        ],
        selected: choice.clamp(0, 2),
        onChanged: (v) => setState(() => choice = v),
      ),
    ]),
    9 => section('choose without friction', [
      BrockmannPicker(
        label: 'full-page choice',
        options: const ['studio', 'library', 'settings', 'about'],
        selected: choice.clamp(0, 3),
        presentation: BrockmannPickerPresentation.fullPage,
        onChanged: (v) => setState(() => choice = v),
      ),
      BrockmannPicker(
        label: 'anchored choice',
        options: const ['studio', 'library', 'settings', 'about'],
        selected: choice.clamp(0, 3),
        presentation: BrockmannPickerPresentation.anchored,
        onChanged: (v) => setState(() => choice = v),
      ),
      BrockmannButton(
        label: 'date / ${date.year}-${date.month}-${date.day}',
        onPressed: () async {
          final v = await showBrockmannDatePicker(
            context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2040),
          );
          if (mounted && v != null) setState(() => date = v);
        },
      ),
      BrockmannButton(
        label: 'time / ${time.format(context)}',
        onPressed: () async {
          final v = await showBrockmannTimePicker(context, initialTime: time);
          if (mounted && v != null) setState(() => time = v);
        },
      ),
      BrockmannButton(
        label: 'action sheet',
        onPressed: () async {
          final v = await showBrockmannActionSheet(
            context,
            title: 'Session actions',
            entries: sessionActions,
          );
          if (context.mounted && v != null) showBrockmannToast(context, v);
        },
      ),
      BrockmannContextMenu<String>(
        entries: sessionActions,
        onSelected: (v) => showBrockmannToast(context, v),
        child: Container(
          padding: const EdgeInsets.all(24),
          color: context.brockmann.surface,
          child: const BrockmannText(
            'Hold here for a context menu. Right-click works too.',
          ),
        ),
      ),
    ]),
    10 => section('one icon language', [
      note(
        'Phosphor regular at 24 dp; bold at small sizes. Every icon button has a spoken label and a 48 dp target.',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final icon in BrockmannIcon.values)
            Tooltip(
              message: icon.name,
              child: BrockmannIconButton(
                icon: icon,
                label: icon.name,
                onPressed: () => showBrockmannToast(context, icon.name),
              ),
            ),
        ],
      ),
    ]),
    _ => section('sound + touch', [
      note(
        'Sound starts off. Essential touch feedback follows Android settings for switches and outcomes. Subtle adds deliberate actions. Continuous controls and scrolling stay quiet.',
      ),
      ListenableBuilder(
        listenable: widget.sound,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrockmannPicker(
              label: 'haptic feedback',
              options: const ['off', 'essential', 'subtle'],
              selected: widget.sound.hapticMode.index,
              onChanged: (v) async {
                await widget.sound.configure(
                  haptics: BrockmannHapticMode.values[v],
                );
                widget.onSound();
              },
            ),
            const SizedBox(height: 24),
            BrockmannPicker(
              label: 'sound mode',
              options: const ['off', 'essential', 'subtle'],
              selected: widget.sound.mode.index,
              onChanged: (v) async {
                await widget.sound.configure(
                  mode: BrockmannSoundMode.values[v],
                );
                widget.onSound();
              },
            ),
            const SizedBox(height: 24),
            BrockmannSlider(
              label: 'sound volume',
              value: widget.sound.volume,
              formatValue: (v) => '${(v * 100).round()}%',
              onChanged: (v) {
                unawaited(widget.sound.configure(volume: v));
                widget.onSound();
              },
            ),
            const SizedBox(height: 16),
            BrockmannText(
              'audio: ${widget.sound.status.name}',
              role: BrockmannType.monoValue,
            ),
          ],
        ),
      ),
      buttons([
        BrockmannButton(
          label: 'confirm / two ticks',
          onPressed: () => widget.sound.play(BrockmannSound.confirm),
        ),
        BrockmannButton(
          label: 'reject / three ticks',
          onPressed: () => widget.sound.play(BrockmannSound.reject),
        ),
      ]),
      note(
        'A short double tick confirms completion. Three spaced ticks communicate rejection. Your Android touch-feedback setting always wins.',
      ),
      buttons([
        for (final cue in BrockmannSound.values)
          BrockmannButton(
            label: cue.assetName,
            onPressed: () => widget.sound.play(cue),
          ),
      ]),
      note(
        'Audition buttons follow the selected mode. Use Subtle to hear all eight cues. Audio preparation never plays a cue; returning from the background never replays old interactions.',
      ),
    ]),
  };
}
