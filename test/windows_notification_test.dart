import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:windows_notification/windows_notification_method_channel.dart';
import 'package:windows_notification/windows_notification_platform_interface.dart';

class _RecordingPlatform
    with MockPlatformInterfaceMixin
    implements WindowsNotificationPlatform {
  String? lastMethod;
  NotificationMessage? lastMessage;
  String? lastApplicationId;
  String? lastTemplate;
  NotificationCallback? lastCallback;
  String? lastAumid;
  String? lastDisplayName;
  String? lastIconPath;

  @override
  Future<void> init() async {
    lastMethod = 'init';
  }

  @override
  Future<void> registerAumid({
    required String aumid,
    required String displayName,
    String? iconPath,
  }) async {
    lastMethod = 'registerAumid';
    lastAumid = aumid;
    lastDisplayName = displayName;
    lastIconPath = iconPath;
  }

  @override
  Future<void> bringAppToForeground() async {
    lastMethod = 'bringAppToForeground';
  }

  @override
  Future<void> showPluginTemplate(
      NotificationMessage message, String? applicationId) async {
    lastMethod = 'showPluginTemplate';
    lastMessage = message;
    lastApplicationId = applicationId;
  }

  @override
  Future<void> showCustomTemplate(NotificationMessage message,
      String? applicationId, String template) async {
    lastMethod = 'showCustomTemplate';
    lastMessage = message;
    lastApplicationId = applicationId;
    lastTemplate = template;
  }

  @override
  Future<void> setCallback(NotificationCallback? callback) async {
    lastCallback = callback;
  }

  @override
  Future<void> clearNotificationHistory(String? applicationId) async {
    lastMethod = 'clearNotificationHistory';
    lastApplicationId = applicationId;
  }

  @override
  Future<void> removeNotification(
      String id, String group, String? applicationId) async {
    lastMethod = 'removeNotification:$id:$group';
    lastApplicationId = applicationId;
  }

  @override
  Future<void> removeNotificationGroup(
      String group, String? applicationId) async {
    lastMethod = 'removeNotificationGroup:$group';
    lastApplicationId = applicationId;
  }
}

void main() {
  group('WindowsNotificationPlatform', () {
    test('default instance is the method channel', () {
      expect(WindowsNotificationPlatform.instance,
          isA<MethodChannelWindowsNotification>());
    });
  });

  group('WindowsNotification public API', () {
    late _RecordingPlatform platform;
    late WindowsNotification notifier;

    setUp(() {
      platform = _RecordingPlatform();
      WindowsNotificationPlatform.instance = platform;
      notifier = WindowsNotification(applicationId: 'app.id');
    });

    test('showNotificationPluginTemplate forwards message and appId', () async {
      final message =
          NotificationMessage.fromPluginTemplate('id-1', 'Hi', 'Hello');
      await notifier.showNotificationPluginTemplate(message);

      expect(platform.lastMethod, 'showPluginTemplate');
      expect(platform.lastMessage, same(message));
      expect(platform.lastApplicationId, 'app.id');
    });

    test('showNotificationCustomTemplate forwards template text', () async {
      final message = NotificationMessage.fromCustomTemplate('id-1');
      await notifier.showNotificationCustomTemplate(message, '<toast/>');

      expect(platform.lastMethod, 'showCustomTemplate');
      expect(platform.lastTemplate, '<toast/>');
    });

    test('removeNotificationId rejects empty id or group', () {
      expect(() => notifier.removeNotificationId('', 'g'), throwsArgumentError);
      expect(() => notifier.removeNotificationId('i', ''), throwsArgumentError);
    });

    test('removeNotificationGroup rejects empty group', () {
      expect(() => notifier.removeNotificationGroup(''), throwsArgumentError);
    });

    test('setCallback registers handler via platform', () async {
      void handler(NotificationCallbackDetails _) {}
      await notifier.setCallback(handler);
      expect(platform.lastCallback, same(handler));
    });
  });

  group('WindowsNotification.registerAumid', () {
    late _RecordingPlatform platform;

    setUp(() {
      platform = _RecordingPlatform();
      WindowsNotificationPlatform.instance = platform;
    });

    test('forwards aumid, displayName, and iconPath', () async {
      await WindowsNotification.registerAumid(
        aumid: 'com.example.app',
        displayName: 'Example',
        iconPath: r'C:\path\to\icon.ico',
      );
      expect(platform.lastMethod, 'registerAumid');
      expect(platform.lastAumid, 'com.example.app');
      expect(platform.lastDisplayName, 'Example');
      expect(platform.lastIconPath, r'C:\path\to\icon.ico');
    });

    test('rejects empty aumid', () {
      expect(
        () => WindowsNotification.registerAumid(
            aumid: '', displayName: 'Example'),
        throwsArgumentError,
      );
    });

    test('rejects aumid longer than 129 characters', () {
      expect(
        () => WindowsNotification.registerAumid(
            aumid: 'a' * 130, displayName: 'Example'),
        throwsArgumentError,
      );
    });

    test('rejects aumid with whitespace', () {
      expect(
        () => WindowsNotification.registerAumid(
            aumid: 'com.example app', displayName: 'Example'),
        throwsArgumentError,
      );
    });

    test('rejects empty displayName', () {
      expect(
        () => WindowsNotification.registerAumid(
            aumid: 'com.example.app', displayName: '   '),
        throwsArgumentError,
      );
    });
  });

  group('NotificationMessage', () {
    test('fromPluginTemplate asserts non-empty id', () {
      expect(
          () => NotificationMessage.fromPluginTemplate('', 'title', 'body'),
          throwsA(isA<AssertionError>()));
    });

    test('fromPluginTemplate records actions and inputs', () {
      final msg = NotificationMessage.fromPluginTemplate(
        'id-1',
        'Title',
        'Body',
        actions: const [
          NotificationAction(content: 'Reply', arguments: 'reply'),
        ],
        inputs: const [
          NotificationInput.text(id: 'message', placeholder: 'Type reply'),
        ],
      );
      expect(msg.actions.single.content, 'Reply');
      expect(msg.inputs.single.id, 'message');
    });

    test('round-trips via callback payload', () {
      final original = NotificationMessage.fromPluginTemplate(
        'id-7',
        'T',
        'B',
        image: 'a.png',
        largeImage: 'b.png',
        group: 'g',
        launch: 'myapp://go',
        payload: const {'k': 'v'},
      );
      final encoded = json.encode(original.toPayloadMap());
      final decoded = NotificationMessage.fromCallbackPayload(encoded);
      expect(decoded.id, 'id-7');
      expect(decoded.title, 'T');
      expect(decoded.body, 'B');
      expect(decoded.image, 'a.png');
      expect(decoded.largeImage, 'b.png');
      expect(decoded.group, 'g');
      expect(decoded.launch, 'myapp://go');
      expect(decoded.payload, const {'k': 'v'});
      expect(decoded.templateType, TemplateType.plugin);
    });
  });
}
