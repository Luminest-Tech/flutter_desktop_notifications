// ignore_for_file: avoid_print

import 'dart:io';

import 'package:example/hero_widgets/calendar_card.dart';
import 'package:example/hero_widgets/download_card.dart';
import 'package:example/hero_widgets/message_card.dart';
import 'package:example/hero_widgets/music_card.dart';
import 'package:example/hero_widgets/stats_card.dart';
import 'package:example/hero_widgets/weather_card.dart';
import 'package:example/templates/alarm_template.dart';
import 'package:example/templates/meeting_template.dart';
import 'package:example/theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:windows_notification/windows_notification.dart';

const _aumid = 'com.example.windows_notification_example';
const _displayName = 'Windows Notification Example';
const _heroSize = Size(364, 180);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowsNotification.registerAumid(
    aumid: _aumid,
    displayName: _displayName,
  );
  runApp(const PlaygroundApp());
}

class PlaygroundApp extends StatefulWidget {
  const PlaygroundApp({super.key});

  @override
  State<PlaygroundApp> createState() => _PlaygroundAppState();
}

class _PlaygroundAppState extends State<PlaygroundApp> {
  ThemeMode _mode = ThemeMode.light;

  void _toggleMode() => setState(
        () => _mode =
            _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _displayName,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _mode,
      home: PlaygroundHome(
        themeMode: _mode,
        onToggleTheme: _toggleMode,
      ),
    );
  }
}

class PlaygroundHome extends StatefulWidget {
  const PlaygroundHome({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<PlaygroundHome> createState() => _PlaygroundHomeState();
}

class _PlaygroundHomeState extends State<PlaygroundHome> {
  final _notifier = WindowsNotification(applicationId: _aumid);
  final List<_EventLogEntry> _events = [];

  @override
  void initState() {
    super.initState();
    _notifier.setCallback(_onNotificationEvent);
  }

  void _onNotificationEvent(NotificationCallbackDetails details) {
    setState(() {
      _events.insert(
        0,
        _EventLogEntry(
          when: DateTime.now(),
          event: details.event,
          messageId: details.message.id,
          arguments: details.arguments,
          userInput: details.userInput,
        ),
      );
      if (_events.length > 8) _events.removeLast();
    });
    print(_events.first);

    if (details.event == NotificationEvent.activated &&
        details.arguments == 'action:open') {
      WindowsNotification.bringAppToForeground();
    }
  }

  Future<String> _downloadTo(String url, String fileName) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$fileName');
    final resp = await http.get(Uri.parse(url));
    await file.writeAsBytes(resp.bodyBytes);
    return file.path;
  }

  // ---- toast factories ----

  Future<void> _simpleToast() => _notifier.showNotificationPluginTemplate(
        NotificationMessage.fromPluginTemplate(
          'simple',
          'Build complete',
          'flutter build windows finished in 34.0s.',
        ),
      );

  Future<void> _replyToast() => _notifier.showNotificationPluginTemplate(
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
      );

  Future<void> _linkToast() async {
    final path = await _downloadTo(
      'https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2@1.5x.png',
      'wiki.png',
    );
    await _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'wiki',
        'Wikipedia',
        'Tap to open the article in your browser.',
        image: path,
        launch: 'https://en.wikipedia.org/wiki/Toast_(computing)',
        activationType: NotificationActivationType.protocol,
      ),
    );
  }

  Future<void> _reminderToast() => _notifier.showNotificationPluginTemplate(
        NotificationMessage.fromPluginTemplate(
          'reminder',
          'Leave for meeting',
          'Design review · Room 2001',
          scenario: NotificationScenario.reminder,
          extraTexts: const [
            NotificationText('10:30 AM — 11:00 AM',
                style: NotificationTextStyle.captionSubtle),
          ],
          attribution: 'Calendar',
        ),
      );

  Future<void> _alarmToast() => _notifier.showNotificationPluginTemplate(
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
      );

  Future<void> _urgentToast() => _notifier.showNotificationPluginTemplate(
        NotificationMessage.fromPluginTemplate(
          'urgent',
          'Production down',
          'api.example.com — 503 for 2 minutes.',
          scenario: NotificationScenario.urgent,
          audio: const NotificationAudio(sound: NotificationSound.Alarm2),
          actions: const [
            NotificationAction(
              content: 'Open dashboard',
              arguments: 'action:open',
              buttonStyle: NotificationButtonStyle.success,
            ),
            NotificationAction(
                content: 'Acknowledge', arguments: 'action:ack'),
          ],
        ),
      );

  Future<void> _silentToast() => _notifier.showNotificationPluginTemplate(
        NotificationMessage.fromPluginTemplate(
          'silent',
          'Backup complete',
          '12.4 GB synced to OneDrive.',
          audio: const NotificationAudio.silent(),
          attribution: 'OneDrive',
        ),
      );

  Future<void> _progressToast() => _notifier.showNotificationPluginTemplate(
        NotificationMessage.fromPluginTemplate(
          'progress',
          'Downloading update',
          'v2.1.0 · 1.2 GB',
          progress: const NotificationProgress(
            title: 'Update installer',
            value: 0.42,
            valueStringOverride: '504 MB of 1.2 GB',
            status: 'Downloading…',
          ),
        ),
      );

  Future<void> _customAlarm() => _notifier.showNotificationCustomTemplate(
        NotificationMessage.fromCustomTemplate('alarm-xml', group: 'demos'),
        alarmTemplate,
      );

  Future<void> _customMeeting() => _notifier.showNotificationCustomTemplate(
        NotificationMessage.fromCustomTemplate('meeting-xml', group: 'demos'),
        meetingTemplate,
      );

  Future<void> _fireHeroWidgetToast(_GalleryItem item) async {
    final path = await WidgetToImage.toPngFile(
      widget: item.builder(),
      size: _heroSize,
      pixelRatio: 2.0,
    );
    await _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'hero-${item.id}',
        item.title,
        item.body,
        heroImage: path,
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
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final basicTiles = [
      _DemoTile(
        label: 'Simple',
        subtitle: 'Title + body, nothing else',
        accent: p.caramel,
        onTap: _simpleToast,
      ),
      _DemoTile(
        label: 'Reply input',
        subtitle: 'Text box + two action buttons',
        accent: p.wine,
        onTap: _replyToast,
      ),
      _DemoTile(
        label: 'Open URL',
        subtitle: 'Image + protocol-launch to browser',
        accent: p.sage,
        onTap: _linkToast,
      ),
    ];
    final scenarioTiles = [
      _DemoTile(
        label: 'Reminder',
        subtitle: 'Persistent · adds a snooze menu',
        accent: p.sage,
        onTap: _reminderToast,
      ),
      _DemoTile(
        label: 'Alarm',
        subtitle: 'Loops until acted on · long duration',
        accent: p.terracotta,
        onTap: _alarmToast,
      ),
      _DemoTile(
        label: 'Urgent',
        subtitle: 'Bypasses Focus Assist · colored button',
        accent: p.wine,
        onTap: _urgentToast,
      ),
    ];
    final richTiles = [
      _DemoTile(
        label: 'Silent',
        subtitle: 'No sound · attribution line',
        accent: p.textTertiary,
        onTap: _silentToast,
      ),
      _DemoTile(
        label: 'Progress bar',
        subtitle: 'Title, value, override label, status',
        accent: p.caramel,
        onTap: _progressToast,
      ),
    ];
    final customTiles = [
      _DemoTile(
        label: 'XML · alarm',
        subtitle: 'Selection input + snooze · raw toast XML',
        accent: p.caramel,
        onTap: _customAlarm,
      ),
      _DemoTile(
        label: 'XML · meeting',
        subtitle: 'Reminder scenario via raw XML',
        accent: p.wine,
        onTap: _customMeeting,
      ),
    ];

    final gallery = <_GalleryItem>[
      _GalleryItem(
        id: 'message',
        title: 'Ada Lovelace',
        body: 'Want to grab lunch?',
        builder: () => const MessageCard(),
      ),
      _GalleryItem(
        id: 'weather',
        title: 'San Francisco · 64°',
        body: 'Partly cloudy · rest of the week looking clear.',
        builder: () => const WeatherCard(),
      ),
      _GalleryItem(
        id: 'music',
        title: 'Now playing',
        body: 'Neil Young — Harvest Moon',
        builder: () => const MusicCard(),
      ),
      _GalleryItem(
        id: 'stats',
        title: 'Active readers · today',
        body: '24,817 · up 12.4% vs yesterday',
        builder: () => const StatsCard(),
      ),
      _GalleryItem(
        id: 'calendar',
        title: 'Design review',
        body: 'In 15 minutes · Room 2001',
        builder: () => const CalendarCard(),
      ),
      _GalleryItem(
        id: 'download',
        title: 'Downloading update',
        body: '504 MB of 1.2 GB · 14.2 MB/s',
        builder: () => const DownloadCard(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [p.caramel, p.terracotta],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: p.cream,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Notification '),
                  TextSpan(
                    text: 'Playground',
                    style: TextStyle(
                      color: p.textTertiary,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _AppBarAction(
            icon: Icons.layers_clear_rounded,
            tooltip: 'Clear notification history',
            onTap: _notifier.clearNotificationHistory,
          ),
          _AppBarAction(
            icon: Icons.delete_sweep_outlined,
            tooltip: 'Remove group "demos"',
            onTap: () => _notifier.removeNotificationGroup('demos'),
          ),
          _AppBarAction(
            icon: widget.themeMode == ThemeMode.light
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            tooltip: widget.themeMode == ThemeMode.light
                ? 'Switch to evening theme'
                : 'Switch to morning theme',
            onTap: widget.onToggleTheme,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Masthead(),
                  const SizedBox(height: 28),
                  const _SectionHeader('Basics'),
                  _TileGrid(tiles: basicTiles),
                  const _SectionHeader('Scenarios'),
                  _TileGrid(tiles: scenarioTiles),
                  const _SectionHeader('Rich content'),
                  _TileGrid(tiles: richTiles),
                  const _SectionHeader('Custom XML'),
                  _TileGrid(tiles: customTiles),
                  const _SectionHeader(
                    'Hero widget gallery',
                    trailing:
                        'Tap a card — Flutter widget rendered via WidgetToImage at 2×',
                  ),
                  _GalleryGrid(
                    items: gallery,
                    onFire: _safeFire,
                  ),
                ],
              ),
            ),
          ),
          _EventLogStrip(events: _events),
        ],
      ),
    );
  }

  Future<void> _safeFire(_GalleryItem item) async {
    try {
      await _fireHeroWidgetToast(item);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rendering/firing toast: $e')),
      );
    }
  }
}

// ---- small components ----

class _Masthead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.surfaceSoft, p.surface],
        ),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A little mood board of toasts.',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(height: 1.05),
                ),
                const SizedBox(height: 10),
                Text(
                  'Every tile below fires a real Windows toast. The gallery at '
                  'the bottom renders any Flutter widget to a PNG via '
                  'WidgetToImage and slots it into the hero image.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          _BrandStamp(),
        ],
      ),
    );
  }
}

class _BrandStamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.caramel, p.terracotta],
        ),
        boxShadow: [
          BoxShadow(
            color: p.softShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(2, (i) {
            final size = 70.0 + i * 20;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: p.cream.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            );
          }),
          Text(
            'v2.1',
            style: TextStyle(
              fontFamily: 'Georgia',
              color: p.cream,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, color: p.textSecondary, size: 20),
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: p.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: p.border),
            ),
            padding: const EdgeInsets.all(10),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 26, 0, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(width: 14),
          if (trailing != null)
            Expanded(
              child: Text(
                trailing!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatefulWidget {
  const _DemoTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.accent,
  });
  final String label;
  final String subtitle;
  final Future<void> Function() onTap;
  final Color accent;

  @override
  State<_DemoTile> createState() => _DemoTileState();
}

class _DemoTileState extends State<_DemoTile> {
  bool _hover = false;
  bool _busy = false;

  Future<void> _handle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onTap();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderColor = _hover ? p.borderStrong : p.border;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hover ? p.surfaceRaised : p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: p.softShadow,
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_busy)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: widget.accent,
                      ),
                    )
                  else
                    Icon(
                      Icons.north_east_rounded,
                      size: 16,
                      color: _hover ? widget.accent : p.textTertiary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final cols = _columns(context, maxExtent: 280);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cols,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 2.4,
      children: tiles,
    );
  }
}

int _columns(BuildContext context, {required double maxExtent}) {
  final width = MediaQuery.of(context).size.width - 56;
  return (width / maxExtent).ceil().clamp(1, 4);
}

// ---- gallery ----

class _GalleryItem {
  _GalleryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.builder,
  });
  final String id;
  final String title;
  final String body;
  final Widget Function() builder;
}

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({required this.items, required this.onFire});
  final List<_GalleryItem> items;
  final Future<void> Function(_GalleryItem) onFire;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.maxWidth / 310).floor().clamp(1, 4);
      const gap = 16.0;
      final tileWidth =
          (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: tileWidth,
              child: _GalleryCard(item: item, onFire: onFire),
            ),
        ],
      );
    });
  }
}

class _GalleryCard extends StatefulWidget {
  const _GalleryCard({required this.item, required this.onFire});
  final _GalleryItem item;
  final Future<void> Function(_GalleryItem) onFire;

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  bool _hover = false;
  bool _busy = false;

  Future<void> _handle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onFire(widget.item);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hover ? p.caramel : p.border,
              width: _hover ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hover
                    ? p.caramel.withValues(alpha: 0.18)
                    : p.softShadow,
                blurRadius: _hover ? 24 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: _heroSize.width / _heroSize.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox.fromSize(
                      size: _heroSize,
                      child: widget.item.builder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_busy)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.8, color: p.caramel),
                    )
                  else
                    Icon(
                      Icons.send_rounded,
                      size: 14,
                      color: _hover ? p.caramel : p.textTertiary,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.body,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- event log ----

class _EventLogEntry {
  _EventLogEntry({
    required this.when,
    required this.event,
    required this.messageId,
    required this.arguments,
    required this.userInput,
  });
  final DateTime when;
  final NotificationEvent event;
  final String messageId;
  final String? arguments;
  final Map<String, String> userInput;

  @override
  String toString() =>
      '${event.name} · id=$messageId · args=$arguments · input=$userInput';
}

class _EventLogStrip extends StatelessWidget {
  const _EventLogStrip({required this.events});
  final List<_EventLogEntry> events;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final latest = events.isEmpty ? null : events.first;
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceSoft,
        border: Border(top: BorderSide(color: p.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: latest == null
                  ? p.textTertiary
                  : _colorFor(p, latest.event),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            latest == null ? 'IDLE' : _label(latest.event).toUpperCase(),
            style: TextStyle(
              color: latest == null
                  ? p.textTertiary
                  : _colorFor(p, latest.event),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              latest == null
                  ? 'Click any tile above to fire a toast.'
                  : '${_fmtTime(latest.when)}  ·  id=${latest.messageId}'
                      '${latest.arguments != null ? '  ·  args=${latest.arguments}' : ''}'
                      '${latest.userInput.isNotEmpty ? '  ·  input=${latest.userInput}' : ''}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: p.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (events.length > 1) ...[
            const SizedBox(width: 12),
            Text(
              '+${events.length - 1} earlier',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  String _label(NotificationEvent e) => switch (e) {
        NotificationEvent.activated => 'activated',
        NotificationEvent.dismissedByUser => 'dismissed',
        NotificationEvent.dismissedByApp => 'hidden',
        NotificationEvent.dismissedByTimeout => 'timed out',
      };

  Color _colorFor(AppPalette p, NotificationEvent e) => switch (e) {
        NotificationEvent.activated => p.sage,
        NotificationEvent.dismissedByUser => p.caramel,
        NotificationEvent.dismissedByApp => p.textTertiary,
        NotificationEvent.dismissedByTimeout => p.wine,
      };

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
