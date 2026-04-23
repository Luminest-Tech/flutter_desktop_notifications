// ignore_for_file: avoid_print

import 'dart:async';
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
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: _displayName,
    theme: buildAppTheme(),
    home: const ExampleApp(),
  ));
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
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

  // ------------ notification factories ------------

  Future<void> _simpleToast() {
    return _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'simple',
        'Build complete',
        'flutter build windows finished in 34.0s.',
      ),
    );
  }

  Future<void> _replyToast() {
    return _notifier.showNotificationPluginTemplate(
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
  }

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

  Future<void> _reminderToast() {
    return _notifier.showNotificationPluginTemplate(
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
  }

  Future<void> _alarmToast() {
    return _notifier.showNotificationPluginTemplate(
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
  }

  Future<void> _urgentToast() {
    return _notifier.showNotificationPluginTemplate(
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
  }

  Future<void> _silentToast() {
    return _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'silent',
        'Backup complete',
        '12.4 GB synced to OneDrive.',
        audio: const NotificationAudio.silent(),
        attribution: 'OneDrive',
      ),
    );
  }

  Future<void> _progressToast() {
    return _notifier.showNotificationPluginTemplate(
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
  }

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

  // ------------ UI ------------

  @override
  Widget build(BuildContext context) {
    final basicTiles = [
      _DemoTile(
        label: 'Simple',
        subtitle: 'Title + body, nothing else',
        onTap: _simpleToast,
        accent: AppColors.mint,
      ),
      _DemoTile(
        label: 'Reply input',
        subtitle: 'Text box + two action buttons',
        onTap: _replyToast,
        accent: AppColors.violet,
      ),
      _DemoTile(
        label: 'Open URL',
        subtitle: 'Image + protocol-launch to browser',
        onTap: _linkToast,
        accent: AppColors.sky,
      ),
    ];
    final scenarioTiles = [
      _DemoTile(
        label: 'Reminder',
        subtitle: 'Persistent, adds a snooze menu',
        onTap: _reminderToast,
        accent: AppColors.sky,
      ),
      _DemoTile(
        label: 'Alarm',
        subtitle: 'Loops until acted on · long duration',
        onTap: _alarmToast,
        accent: AppColors.amber,
      ),
      _DemoTile(
        label: 'Urgent',
        subtitle: 'Bypasses Focus Assist · colored button',
        onTap: _urgentToast,
        accent: AppColors.coral,
      ),
    ];
    final richTiles = [
      _DemoTile(
        label: 'Silent',
        subtitle: 'No sound · attribution line',
        onTap: _silentToast,
        accent: AppColors.textTertiary,
      ),
      _DemoTile(
        label: 'Progress bar',
        subtitle: 'Title, value, override label, status',
        onTap: _progressToast,
        accent: AppColors.mint,
      ),
    ];
    final customTiles = [
      _DemoTile(
        label: 'XML · alarm',
        subtitle: 'Selection input + snooze · custom toast XML',
        onTap: _customAlarm,
        accent: AppColors.violet,
      ),
      _DemoTile(
        label: 'XML · meeting',
        subtitle: 'Reminder scenario via raw XML',
        onTap: _customMeeting,
        accent: AppColors.violet,
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
        body: "M83 — Midnight City",
        builder: () => const MusicCard(),
      ),
      _GalleryItem(
        id: 'stats',
        title: 'Active users · today',
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: const LinearGradient(
                  colors: [AppColors.mint, AppColors.sky],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF001F16),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Windows Notification '),
                  TextSpan(
                    text: '· playground',
                    style: TextStyle(
                      color: AppColors.textTertiary,
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
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Basics'),
                  _TileGrid(tiles: basicTiles),
                  _sectionHeader('Scenarios'),
                  _TileGrid(tiles: scenarioTiles),
                  _sectionHeader('Rich content'),
                  _TileGrid(tiles: richTiles),
                  _sectionHeader('Custom XML'),
                  _TileGrid(tiles: customTiles),
                  _sectionHeader(
                    'Hero widget gallery',
                    trailing:
                        'Tap a card · Flutter widget rendered via WidgetToImage at 2×',
                  ),
                  _GalleryGrid(
                    items: gallery,
                    onFire: _fireHeroWidgetToastWithErrors,
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

  Future<void> _fireHeroWidgetToastWithErrors(_GalleryItem item) async {
    try {
      await _fireHeroWidgetToast(item);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rendering/firing toast: $e')));
    }
  }

  Widget _sectionHeader(String text, {String? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 24, 0, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 12),
            if (trailing != null)
              Expanded(
                child: Text(
                  trailing,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
}

// ------------ small UI pieces ------------

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
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, color: AppColors.textSecondary, size: 20),
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(10),
          ),
        ),
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
    final borderColor =
        _hover ? AppColors.borderStrong : AppColors.border;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
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
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.8),
                    )
                  else
                    Icon(
                      Icons.north_east_rounded,
                      size: 16,
                      color: _hover ? AppColors.mint : AppColors.textTertiary,
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _columns(context, maxExtent: 280),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: tiles,
    );
  }
}

int _columns(BuildContext context, {required double maxExtent}) {
  final width = MediaQuery.of(context).size.width - 48;
  return (width / maxExtent).ceil().clamp(1, 4);
}

// ------------ gallery ------------

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
      final columns = (constraints.maxWidth / 300).floor().clamp(1, 4);
      const gap = 14.0;
      final tileWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover ? AppColors.mint : AppColors.border,
              width: _hover ? 1.2 : 1,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: AppColors.mint.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: _heroSize.width / _heroSize.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.8),
                    )
                  else
                    Icon(
                      Icons.send_rounded,
                      size: 14,
                      color: _hover
                          ? AppColors.mint
                          : AppColors.textTertiary,
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

// ------------ event log ------------

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
    final latest = events.isEmpty ? null : events.first;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: latest == null
                  ? AppColors.textTertiary
                  : _colorFor(latest.event),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            latest == null ? 'IDLE' : _label(latest.event).toUpperCase(),
            style: TextStyle(
              color: latest == null
                  ? AppColors.textTertiary
                  : _colorFor(latest.event),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
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
                  ?.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (events.length > 1) ...[
            const SizedBox(width: 12),
            Text(
              '+${events.length - 1}',
              style: Theme.of(context).textTheme.labelMedium,
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
        NotificationEvent.dismissedByTimeout => 'timeout',
      };

  Color _colorFor(NotificationEvent e) => switch (e) {
        NotificationEvent.activated => AppColors.mint,
        NotificationEvent.dismissedByUser => AppColors.sky,
        NotificationEvent.dismissedByApp => AppColors.textTertiary,
        NotificationEvent.dismissedByTimeout => AppColors.amber,
      };

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
