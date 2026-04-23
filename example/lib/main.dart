// ignore_for_file: avoid_print

import 'dart:io';

import 'package:example/rich_toast_card.dart';
import 'package:example/templates/alarm_template.dart';
import 'package:example/templates/meeting_template.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:windows_notification/windows_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowsNotification.registerAumid(
    aumid: _aumid,
    displayName: _displayName,
  );
  runApp(const MaterialApp(home: ExampleApp()));
}

const _aumid = 'com.example.windows_notification_example';
const _displayName = 'Windows Notification Example';

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _notifier = WindowsNotification(applicationId: _aumid);
  String _lastEvent = '';

  @override
  void initState() {
    super.initState();
    _notifier.setCallback(_handleNotificationEvent);
  }

  void _handleNotificationEvent(NotificationCallbackDetails details) {
    setState(() {
      _lastEvent = 'event=${details.event.name} '
          'args=${details.arguments} '
          'input=${details.userInput} '
          'id=${details.message.id}';
    });
    print(_lastEvent);

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

  Future<void> _simpleToast() async {
    await _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'simple',
        'Hello',
        'Body text goes here.',
        payload: const {'action': 'open_home'},
      ),
    );
  }

  Future<void> _replyToast() async {
    await _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'reply',
        'New message from Ada',
        'Want to grab lunch?',
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

  Future<void> _imageToast() async {
    final path = await _downloadTo(
      'https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2@1.5x.png',
      'wiki.png',
    );
    await _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'wiki',
        'Wikipedia',
        'Tap to open the article.',
        image: path,
        launch: 'https://en.wikipedia.org/wiki/Toast_(computing)',
        activationType: NotificationActivationType.protocol,
      ),
    );
  }

  Future<void> _reminderToast() async {
    await _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'reminder',
        'Leave for meeting',
        'Adaptive Tiles Meeting · Conf Room 2001',
        scenario: NotificationScenario.reminder,
        extraTexts: const [
          NotificationText('10:00 AM – 10:30 AM',
              style: NotificationTextStyle.captionSubtle),
        ],
        attribution: 'Calendar',
      ),
    );
  }

  Future<void> _alarmToast() async {
    await _notifier.showNotificationPluginTemplate(
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
              buttonStyle: NotificationButtonStyle.critical),
        ],
      ),
    );
  }

  Future<void> _urgentToast() async {
    await _notifier.showNotificationPluginTemplate(
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

  Future<void> _silentToast() async {
    await _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'silent',
        'Backup complete',
        '12.4 GB synced to OneDrive.',
        audio: const NotificationAudio.silent(),
        attribution: 'OneDrive',
      ),
    );
  }

  Future<void> _progressToast() async {
    await _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'progress',
        'Downloading update',
        'v2.0.0 · 1.2 GB',
        progress: const NotificationProgress(
          title: 'Update installer',
          value: 0.42,
          valueStringOverride: '504 MB of 1.2 GB',
          status: 'Downloading…',
        ),
      ),
    );
  }

  Future<void> _richWidgetToast() async {
    final heroPath = await WidgetToImage.toPngFile(
      widget: const RichToastCard(
        sender: 'Ada Lovelace',
        preview: "Hey — want to grab lunch? I'll be free at 12:30.",
      ),
      size: const Size(364, 180),
      pixelRatio: 2.0,
    );
    await _notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        'rich-widget',
        'Ada Lovelace',
        'Lunch?',
        heroImage: heroPath,
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

  Future<void> _customAlarm() async {
    await _notifier.showNotificationCustomTemplate(
      NotificationMessage.fromCustomTemplate('alarm-xml', group: 'demos'),
      alarmTemplate,
    );
  }

  Future<void> _customMeeting() async {
    await _notifier.showNotificationCustomTemplate(
      NotificationMessage.fromCustomTemplate('meeting', group: 'demos'),
      meetingTemplate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('windows_notification example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel(context, 'Basic'),
          _button('Simple toast', _simpleToast),
          _button('Toast with reply input + action buttons', _replyToast),
          _button('Toast with image + launch URL', _imageToast),
          _sectionLabel(context, 'Scenarios'),
          _button('Reminder (snooze UI)', _reminderToast),
          _button('Alarm (persistent, looping sound)', _alarmToast),
          _button('Urgent (bypasses Focus Assist)', _urgentToast),
          _sectionLabel(context, 'Rich content'),
          _button('Silent toast with attribution', _silentToast),
          _button('Progress bar', _progressToast),
          _button('Hero image rendered from Flutter widget', _richWidgetToast),
          _sectionLabel(context, 'Custom XML'),
          _button('Custom XML: alarm', _customAlarm),
          _button('Custom XML: meeting', _customMeeting),
          _sectionLabel(context, 'Cleanup'),
          _button('Clear notification history',
              _notifier.clearNotificationHistory),
          _button('Remove group "demos"',
              () => _notifier.removeNotificationGroup('demos')),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _lastEvent.isEmpty ? 'No events yet' : _lastEvent,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );

  Widget _button(String label, Future<void> Function() onPressed) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ElevatedButton(
          onPressed: () async {
            try {
              await onPressed();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error: $e'),
              ));
            }
          },
          child: Text(label),
        ),
      );
}
