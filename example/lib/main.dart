// ignore_for_file: avoid_print

import 'dart:io';

import 'package:example/templates/alarm_template.dart';
import 'package:example/templates/meeting_template.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:windows_notification/windows_notification.dart';

void main() {
  runApp(const MaterialApp(home: ExampleApp()));
}

// For unpackaged apps, Windows won't actually show a toast unless the AUMID
// you pass here is registered somewhere (e.g., a Start Menu shortcut with
// `System.AppUserModel.ID` set). The PowerShell AUMID below happens to be
// pre-registered on every Windows 10/11 box, which makes it convenient for
// quick demos only — don't ship this.
const _aumid = r'{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe';

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
    _notifier.setCallback((details) {
      setState(() {
        _lastEvent = 'event=${details.event.name} '
            'args=${details.arguments} '
            'input=${details.userInput} '
            'id=${details.message.id}';
      });
      print(_lastEvent);
    });
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
      ),
    );
  }

  Future<void> _customAlarm() async {
    await _notifier.showNotificationCustomTemplate(
      NotificationMessage.fromCustomTemplate('alarm', group: 'demos'),
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
          _button('Simple toast', _simpleToast),
          _button('Toast with reply input + action buttons', _replyToast),
          _button('Toast with image + launch URL', _imageToast),
          _button('Custom XML: alarm', _customAlarm),
          _button('Custom XML: meeting', _customMeeting),
          const Divider(),
          _button('Clear notification history', _notifier.clearNotificationHistory),
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

  Widget _button(String label, Future<void> Function() onPressed) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
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
