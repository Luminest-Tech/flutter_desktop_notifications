import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_windows_notification/flutter_windows_notification.dart';

const _aumid = 'io.luminest.flutter_windows_notification.example';
const _displayName = 'Windows Notification Demo';
const _heroSize = Size(364, 180);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Unpackaged apps need a registered AUMID or Windows drops the toast.
  await WindowsNotification.registerAumid(
    aumid: _aumid,
    displayName: _displayName,
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  /// Selectable accent colors for the demo's theme.
  static const List<(String, Color)> swatches = [
    ('Violet', Color(0xFF7C4DFF)),
    ('Indigo', Color(0xFF3F51B5)),
    ('Blue', Color(0xFF2196F3)),
    ('Teal', Color(0xFF009688)),
    ('Green', Color(0xFF43A047)),
    ('Amber', Color(0xFFFFB300)),
    ('Orange', Color(0xFFFB8C00)),
    ('Rose', Color(0xFFEC407A)),
  ];

  Color _seed = swatches.first.$2;
  ThemeMode _mode = ThemeMode.light;

  ThemeData _theme(Brightness brightness) => ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
        useMaterial3: true,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'flutter_windows_notification demo',
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _mode,
      home: HomePage(
        swatches: swatches,
        seed: _seed,
        isDark: _mode == ThemeMode.dark,
        onSeedChanged: (c) => setState(() => _seed = c),
        onDarkChanged: (d) =>
            setState(() => _mode = d ? ThemeMode.dark : ThemeMode.light),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<(String, Color)> swatches;
  final Color seed;
  final bool isDark;
  final ValueChanged<Color> onSeedChanged;
  final ValueChanged<bool> onDarkChanged;

  const HomePage({
    super.key,
    required this.swatches,
    required this.seed,
    required this.isDark,
    required this.onSeedChanged,
    required this.onDarkChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _notifier = WindowsNotification(applicationId: _aumid);
  String _status = 'No event yet — fire a toast above, then click it.';

  @override
  void initState() {
    super.initState();
    _notifier.setCallback(_onEvent);
  }

  void _onEvent(NotificationCallbackDetails details) {
    final parts = <String>['id=${details.message.id}'];
    if (details.arguments != null) parts.add('args=${details.arguments}');
    if (details.userInput.isNotEmpty) parts.add('input=${details.userInput}');
    setState(() => _status = '${_eventLabel(details.event)}  ·  '
        '${parts.join("  ·  ")}');

    // "Open" buttons should pull the app back to the front.
    if (details.event == NotificationEvent.activated &&
        details.arguments == 'action:open') {
      WindowsNotification.bringAppToForeground();
    }
  }

  String _eventLabel(NotificationEvent e) => switch (e) {
        NotificationEvent.activated => 'ACTIVATED',
        NotificationEvent.dismissedByUser => 'DISMISSED',
        NotificationEvent.dismissedByApp => 'HIDDEN',
        NotificationEvent.dismissedByTimeout => 'TIMED OUT',
      };

  /// Sets a status line, runs [action], and reports any failure.
  Future<void> _run(String fired, Future<void> Function() action) async {
    setState(() => _status = fired);
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _simpleToast() => _run(
        'Fired the Simple toast — title and body only.',
        () => _notifier.showNotificationPluginTemplate(
          NotificationMessage.fromPluginTemplate(
            'simple',
            'Build complete',
            'flutter build windows finished in 34.0s.',
          ),
        ),
      );

  Future<void> _replyToast() => _run(
        'Fired the Reply toast — type something, then click Reply.',
        () => _notifier.showNotificationPluginTemplate(
          NotificationMessage.fromPluginTemplate(
            'reply',
            'Ada Lovelace',
            'Want to grab lunch at 12:30?',
            inputs: const [
              NotificationInput.text(id: 'reply', placeholder: 'Quick reply…'),
            ],
            actions: const [
              NotificationAction(
                content: 'Reply',
                arguments: 'action:reply',
                inputId: 'reply',
              ),
              NotificationAction(
                content: 'Dismiss',
                arguments: 'action:dismiss',
                buttonStyle: NotificationButtonStyle.critical,
              ),
            ],
          ),
        ),
      );

  Future<void> _linkToast() => _run(
        'Fired a toast that opens flutter.dev in your browser.',
        () => _notifier.showNotificationPluginTemplate(
          NotificationMessage.fromPluginTemplate(
            'link',
            'Flutter',
            'Tap the toast body to open flutter.dev.',
            launch: 'https://flutter.dev',
            activationType: NotificationActivationType.protocol,
          ),
        ),
      );

  Future<void> _reminderToast() => _run(
        'Fired a Reminder — it stays until you act on it.',
        () => _notifier.showNotificationPluginTemplate(
          NotificationMessage.fromPluginTemplate(
            'reminder',
            'Leave for meeting',
            'Design review · Room 2001',
            scenario: NotificationScenario.reminder,
            extraTexts: const [
              NotificationText('10:30 to 11:00 AM',
                  style: NotificationTextStyle.captionSubtle),
            ],
            attribution: 'Calendar',
          ),
        ),
      );

  Future<void> _alarmToast() => _run(
        'Fired an Alarm — loops its sound until dismissed.',
        () => _notifier.showNotificationPluginTemplate(
          NotificationMessage.fromPluginTemplate(
            'alarm',
            'Morning alarm',
            '7:00 AM',
            scenario: NotificationScenario.alarm,
            duration: NotificationDuration.long,
            audio: const NotificationAudio(
              sound: NotificationSound.Alarm,
              loop: true,
            ),
            actions: const [
              NotificationAction(content: 'Snooze', arguments: 'action:snooze'),
              NotificationAction(
                content: 'Dismiss',
                arguments: 'action:dismiss',
                buttonStyle: NotificationButtonStyle.critical,
              ),
            ],
          ),
        ),
      );

  Future<void> _urgentToast() => _run(
        'Fired an Urgent toast — bypasses Focus Assist.',
        () => _notifier.showNotificationPluginTemplate(
          NotificationMessage.fromPluginTemplate(
            'urgent',
            'Production down',
            'api.example.com · 503 for 2 minutes.',
            scenario: NotificationScenario.urgent,
            audio: const NotificationAudio(sound: NotificationSound.Alarm2),
            actions: const [
              NotificationAction(
                content: 'Open dashboard',
                arguments: 'action:open',
                buttonStyle: NotificationButtonStyle.success,
              ),
              NotificationAction(
                content: 'Acknowledge',
                arguments: 'action:ack',
              ),
            ],
          ),
        ),
      );

  Future<void> _silentToast() => _run(
        'Fired a Silent toast — no sound, with an attribution line.',
        () => _notifier.showNotificationPluginTemplate(
          NotificationMessage.fromPluginTemplate(
            'silent',
            'Backup complete',
            '12.4 GB synced to OneDrive.',
            audio: const NotificationAudio.silent(),
            attribution: 'OneDrive',
          ),
        ),
      );

  Future<void> _progressToast() => _run(
        'Fired a Progress toast — shows a determinate progress bar.',
        () => _notifier.showNotificationPluginTemplate(
          NotificationMessage.fromPluginTemplate(
            'progress',
            'Downloading update',
            'v1.0.0 · 1.2 GB',
            progress: const NotificationProgress(
              title: 'Update installer',
              value: 0.42,
              valueStringOverride: '504 MB of 1.2 GB',
              status: 'Downloading…',
            ),
          ),
        ),
      );

  Future<void> _customXmlToast() => _run(
        'Fired a toast from hand-written toast XML.',
        () => _notifier.showNotificationCustomTemplate(
          NotificationMessage.fromCustomTemplate('meeting-xml', group: 'demos'),
          _meetingTemplate,
        ),
      );

  Future<void> _heroToast() => _run(
        'Rendered a Flutter widget and used it as the hero image.',
        () async {
          final theme = Theme.of(context);
          final path = await WidgetToImage.toPngFile(
            widget: const _MessageHeroCard(),
            size: _heroSize,
            pixelRatio: 2.0,
            theme: theme,
          );
          await _notifier.showNotificationPluginTemplate(
            NotificationMessage.fromPluginTemplate(
              'hero',
              'Ada Lovelace',
              'Want to grab lunch at 12:30?',
              heroImage: path,
              group: 'demos',
              actions: const [
                NotificationAction(
                  content: 'Open',
                  arguments: 'action:open',
                  buttonStyle: NotificationButtonStyle.success,
                ),
                NotificationAction(
                  content: 'Dismiss',
                  arguments: 'action:dismiss',
                ),
              ],
            ),
          );
        },
      );

  Future<void> _clearHistory() => _run(
        "Cleared this app's notification history.",
        _notifier.clearNotificationHistory,
      );

  Future<void> _removeGroup() => _run(
        'Removed the "demos" group from the Action Center.',
        () => _notifier.removeNotificationGroup('demos'),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final gradient = dark
        ? [
            Color.alphaBlend(cs.primary.withValues(alpha: 0.30), cs.surface),
            Color.alphaBlend(cs.tertiary.withValues(alpha: 0.26), cs.surface),
          ]
        : [cs.primary, cs.tertiary];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox.expand(child: _panel(cs)),
          ),
        ),
      ),
    );
  }

  Widget _panel(ColorScheme cs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(cs),
                      const SizedBox(height: 28),
                      _themeControls(cs),
                      const SizedBox(height: 28),
                      _buttons(cs),
                      const SizedBox(height: 18),
                      _maintenanceRow(cs),
                      const SizedBox(height: 22),
                      _helpCard(cs),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _resultCard(cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ColorScheme cs) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.notifications_active_rounded,
              color: cs.onPrimaryContainer, size: 30),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'flutter_windows_notification',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Native Windows toast notifications, sent straight from Flutter.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _themeControls(ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accent color',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (name, color) in widget.swatches)
                    _SwatchDot(
                      name: name,
                      color: color,
                      selected: widget.seed.toARGB32() == color.toARGB32(),
                      onTap: () => widget.onSeedChanged(color),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Appearance',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    )),
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                  label: Text('Dark'),
                ),
              ],
              selected: {widget.isDark},
              onSelectionChanged: (s) => widget.onDarkChanged(s.first),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buttons(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Send a notification',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = (constraints.maxWidth / 300).floor().clamp(1, 4);
            final cellWidth = (constraints.maxWidth - (cols - 1) * 14) / cols;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _ActionButton(
                  width: cellWidth,
                  icon: Icons.notifications_active_outlined,
                  label: 'Simple',
                  description: 'Title and body, nothing else',
                  onTap: _simpleToast,
                ),
                _ActionButton(
                  width: cellWidth,
                  icon: Icons.reply_outlined,
                  label: 'Reply input',
                  description: 'Text box plus two buttons',
                  onTap: _replyToast,
                ),
                _ActionButton(
                  width: cellWidth,
                  icon: Icons.open_in_browser_outlined,
                  label: 'Open link',
                  description: 'Protocol-launch to the browser',
                  onTap: _linkToast,
                ),
                _ActionButton(
                  width: cellWidth,
                  icon: Icons.schedule_outlined,
                  label: 'Reminder',
                  description: 'Persistent · adds a snooze menu',
                  onTap: _reminderToast,
                ),
                _ActionButton(
                  width: cellWidth,
                  icon: Icons.alarm_outlined,
                  label: 'Alarm',
                  description: 'Loops until acted on · long',
                  onTap: _alarmToast,
                ),
                _ActionButton(
                  width: cellWidth,
                  icon: Icons.priority_high_rounded,
                  label: 'Urgent',
                  description: 'Bypasses Focus Assist',
                  onTap: _urgentToast,
                ),
                _ActionButton(
                  width: cellWidth,
                  icon: Icons.notifications_off_outlined,
                  label: 'Silent',
                  description: 'No sound · attribution line',
                  onTap: _silentToast,
                ),
                _ActionButton(
                  width: cellWidth,
                  icon: Icons.downloading_outlined,
                  label: 'Progress bar',
                  description: 'Value, override label, status',
                  onTap: _progressToast,
                ),
                _ActionButton(
                  width: cellWidth,
                  icon: Icons.code_outlined,
                  label: 'Custom XML',
                  description: 'Hand-written toast XML',
                  onTap: _customXmlToast,
                ),
                _ActionButton(
                  width: constraints.maxWidth,
                  icon: Icons.image_outlined,
                  label: 'Hero image from a widget',
                  description:
                      'Rasterizes a Flutter widget with WidgetToImage and '
                      'drops it into the toast',
                  primary: true,
                  onTap: _heroToast,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _maintenanceRow(ColorScheme cs) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: _clearHistory,
          icon: const Icon(Icons.layers_clear_outlined, size: 18),
          label: const Text('Clear history'),
        ),
        OutlinedButton.icon(
          onPressed: _removeGroup,
          icon: const Icon(Icons.delete_sweep_outlined, size: 18),
          label: const Text('Remove "demos" group'),
        ),
      ],
    );
  }

  Widget _helpCard(ColorScheme cs) {
    const tips = [
      'Click a toast — its body tap, buttons, and dismissal show up below',
      'Type in the Reply box, then click Reply to read the text back',
      'Open the Action Center (Win + N) to see delivered toasts',
      'Alarm and Urgent use different sounds and bypass Focus Assist',
      'Hero image renders a live Flutter widget into the toast',
      'Recolor everything from the accent swatches — the hero image follows',
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text('Things to try',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.check_circle_outline,
                        size: 17, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(tip,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt_rounded, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              _status,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// A circular accent-color swatch with a selection ring + check.
class _SwatchDot extends StatelessWidget {
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SwatchDot({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;
    return Tooltip(
      message: name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? cs.onSurface : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              selected ? Icon(Icons.check, size: 18, color: checkColor) : null,
        ),
      ),
    );
  }
}

/// A large, card-style button with icon, title, and description.
class _ActionButton extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = primary ? cs.onPrimary : cs.onSurface;
    final sub =
        primary ? cs.onPrimary.withValues(alpha: 0.85) : cs.onSurfaceVariant;
    final iconBg =
        primary ? cs.onPrimary.withValues(alpha: 0.18) : cs.primaryContainer;
    final iconFg = primary ? cs.onPrimary : cs.onPrimaryContainer;

    return SizedBox(
      width: width,
      child: Material(
        color: primary ? cs.primary : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconFg, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(fontSize: 12.5, color: sub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: sub),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rendered off-screen by [WidgetToImage] and used as a toast hero image.
/// Sized for the 364 x 180 hero slot; picks up the app's accent via [Theme].
class _MessageHeroCard extends StatelessWidget {
  const _MessageHeroCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.tertiary],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.onPrimary.withValues(alpha: 0.18),
                border: Border.all(
                  color: cs.onPrimary.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Text(
                'AL',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ada Lovelace',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '12:24',
                        style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Want to grab lunch at 12:30? I found a new ramen place '
                    'around the corner.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onPrimary.withValues(alpha: 0.92),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hand-written toast XML, shown by the "Custom XML" button. Anything the
/// structured builder doesn't cover can be sent as a raw template like this.
const _meetingTemplate = '''
<toast scenario="reminder" launch="open=event&amp;id=1983">
  <visual>
    <binding template="ToastGeneric">
      <text>Design review</text>
      <text>Room 2001 · Building 135</text>
      <text>10:00 AM - 10:30 AM</text>
    </binding>
  </visual>
  <actions>
    <input id="snoozeTime" type="selection" defaultInput="15">
      <selection id="1" content="1 minute"/>
      <selection id="15" content="15 minutes"/>
      <selection id="60" content="1 hour"/>
    </input>
    <action activationType="system" arguments="snooze" hint-inputId="snoozeTime" content=""/>
    <action activationType="system" arguments="dismiss" content=""/>
  </actions>
</toast>
''';
