import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_desktop_notifications/flutter_desktop_notifications.dart';
import 'package:flutter_desktop_notifications/windows_notification_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelWindowsNotification', () {
    late MethodChannelWindowsNotification platform;
    late List<MethodCall> calls;

    setUp(() {
      platform = MethodChannelWindowsNotification();
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
    });

    test('showPluginTemplate sends a show_toast with composed XML', () async {
      final msg = NotificationMessage.fromPluginTemplate(
        'id-1',
        'Title',
        'Body',
        image: 'avatar.png',
        launch: 'myapp://go',
        group: 'mail',
        actions: const [
          NotificationAction(content: 'Reply', arguments: 'reply'),
        ],
        inputs: const [
          NotificationInput.text(id: 'reply', placeholder: 'Type...'),
        ],
      );

      await platform.showPluginTemplate(msg, 'my.app');

      expect(calls, hasLength(1));
      final args = calls.single.arguments as Map;
      expect(calls.single.method, 'show_toast');
      expect(args['tag'], 'id-1');
      expect(args['group'], 'mail');
      expect(args['launch'], 'myapp://go');
      expect(args['application_id'], 'my.app');

      final xml = args['template'] as String;
      expect(xml, contains('<text>Title</text>'));
      expect(xml, contains('<text>Body</text>'));
      expect(xml, contains('avatar.png'));
      expect(xml, contains('<action'));
      expect(xml, contains('<input'));
    });

    test('showCustomTemplate forwards the raw template', () async {
      final msg = NotificationMessage.fromCustomTemplate('id-2');
      const template = '<toast><visual/></toast>';
      await platform.showCustomTemplate(msg, null, template);

      expect(calls.single.method, 'show_toast');
      final args = calls.single.arguments as Map;
      expect(args['template'], template);
      expect(args.containsKey('application_id'), isFalse);
    });

    test('payload is JSON-encoded and round-trippable', () async {
      final msg = NotificationMessage.fromPluginTemplate(
        'id-3',
        'T',
        'B',
        payload: const {'key': 'value'},
      );
      await platform.showPluginTemplate(msg, null);

      final args = calls.single.arguments as Map;
      final decoded = json.decode(args['payload'] as String);
      expect(decoded['tag'], 'id-3');
      expect(decoded['payload'], {'key': 'value'});
    });

    test('emits scenario, duration, attribution, hero image, audio, progress',
        () async {
      final msg = NotificationMessage.fromPluginTemplate(
        'rich',
        'Title',
        'Body',
        heroImage: 'hero.png',
        attribution: 'Source',
        scenario: NotificationScenario.urgent,
        duration: NotificationDuration.long,
        audio: const NotificationAudio(
            sound: NotificationSound.Alarm, loop: true),
        progress: const NotificationProgress(
          title: 'Upload',
          value: 0.5,
          valueStringOverride: '50 of 100',
          status: 'Uploading…',
        ),
        extraTexts: const [
          NotificationText('Subtitle line',
              style: NotificationTextStyle.captionSubtle),
        ],
      );
      await platform.showPluginTemplate(msg, null);
      final xml = (calls.single.arguments as Map)['template'] as String;

      expect(xml, contains('scenario="urgent"'));
      expect(xml, contains('duration="long"'));
      expect(xml, contains('placement="hero" src="hero.png"'));
      expect(xml, contains('placement="attribution">Source</text>'));
      expect(xml, contains('hint-style="captionSubtle"'));
      expect(
          xml,
          contains(
              '<audio src="ms-winsoundevent:Notification.Alarm" loop="true"/>'));
      expect(xml, contains('<progress'));
      expect(xml, contains('title="Upload"'));
      expect(xml, contains('value="0.5"'));
      expect(xml, contains('valueStringOverride="50 of 100"'));
      expect(xml, contains('status="Uploading…"'));
    });

    test('context-menu actions get placement="contextMenu"', () async {
      final msg = NotificationMessage.fromPluginTemplate(
        'menu',
        'T',
        'B',
        actions: const [
          NotificationAction(
              content: 'Report', arguments: 'a:report', contextMenu: true),
        ],
      );
      await platform.showPluginTemplate(msg, null);
      final xml = (calls.single.arguments as Map)['template'] as String;
      expect(xml, contains('placement="contextMenu"'));
    });

    test('silent audio emits <audio silent="true"/>', () async {
      final msg = NotificationMessage.fromPluginTemplate(
        'q',
        'T',
        'B',
        audio: const NotificationAudio.silent(),
      );
      await platform.showPluginTemplate(msg, null);
      final xml = (calls.single.arguments as Map)['template'] as String;
      expect(xml, contains('<audio silent="true"/>'));
    });

    test('indeterminate progress serializes as "indeterminate"', () async {
      final msg = NotificationMessage.fromPluginTemplate(
        'i',
        'T',
        'B',
        progress: const NotificationProgress(status: 'Working'),
      );
      await platform.showPluginTemplate(msg, null);
      final xml = (calls.single.arguments as Map)['template'] as String;
      expect(xml, contains('value="indeterminate"'));
    });

    test('setCallback delivers activation events', () async {
      NotificationCallbackDetails? received;
      await platform.setCallback((d) => received = d);

      final payloadJson = json.encode(NotificationMessage.fromPluginTemplate(
              'id-4', 'T', 'B',
              payload: const {'hello': 'world'})
          .toPayloadMap());

      final codec = platform.methodChannel.codec;
      final envelope = codec.encodeMethodCall(MethodCall('activated', {
        'payload': payloadJson,
        'arguments': 'clicked',
        'user_input': {'reply': 'thanks'},
      }));
      await TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .handlePlatformMessage('windows_notification', envelope, (_) {});

      expect(received, isNotNull);
      expect(received!.event, NotificationEvent.activated);
      expect(received!.arguments, 'clicked');
      expect(received!.userInput, {'reply': 'thanks'});
      expect(received!.message.id, 'id-4');
      expect(received!.message.payload, {'hello': 'world'});
    });
  });
}
