import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:windows_notification/windows_notification_method_channel.dart';

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
