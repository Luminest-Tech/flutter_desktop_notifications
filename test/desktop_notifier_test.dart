import 'package:flutter_desktop_notifications/flutter_desktop_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeDesktop
    with MockPlatformInterfaceMixin
    implements DesktopNotificationsPlatform {
  String? lastMethod;
  NotificationMessage? lastMessage;
  String? lastAppName;
  String? lastAppId;
  String? lastCancelId;
  String? lastCancelGroup;
  NotificationCallback? lastHandler;

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async {
    lastMethod = 'requestPermission';
    return true;
  }

  @override
  Future<void> show(NotificationMessage message,
      {String? appName, String? appId}) async {
    lastMethod = 'show';
    lastMessage = message;
    lastAppName = appName;
    lastAppId = appId;
  }

  @override
  Future<void> setHandler(NotificationCallback? handler) async {
    lastMethod = 'setHandler';
    lastHandler = handler;
  }

  @override
  Future<void> cancel(String id, {String? group, String? appId}) async {
    lastMethod = 'cancel';
    lastCancelId = id;
    lastCancelGroup = group;
    lastAppId = appId;
  }

  @override
  Future<void> cancelAll({String? appId}) async {
    lastMethod = 'cancelAll';
    lastAppId = appId;
  }
}

void main() {
  group('DesktopNotifier', () {
    late _FakeDesktop fake;

    setUp(() {
      fake = _FakeDesktop();
      DesktopNotificationsPlatform.instance = fake;
    });

    test('show forwards the message and appName/appId', () async {
      final notifier = DesktopNotifier(appName: 'My App', appId: 'com.x.app');
      final message = NotificationMessage.fromPluginTemplate('id', 'T', 'B');

      await notifier.show(message);

      expect(fake.lastMethod, 'show');
      expect(fake.lastMessage, same(message));
      expect(fake.lastAppName, 'My App');
      expect(fake.lastAppId, 'com.x.app');
    });

    test('setCallback forwards the handler', () async {
      final notifier = DesktopNotifier();
      void handler(NotificationCallbackDetails _) {}
      await notifier.setCallback(handler);
      expect(fake.lastMethod, 'setHandler');
      expect(fake.lastHandler, same(handler));
    });

    test('cancel forwards id, group, and appId', () async {
      final notifier = DesktopNotifier(appId: 'com.x.app');
      await notifier.cancel('id-1', group: 'g');
      expect(fake.lastMethod, 'cancel');
      expect(fake.lastCancelId, 'id-1');
      expect(fake.lastCancelGroup, 'g');
      expect(fake.lastAppId, 'com.x.app');
    });

    test('cancelAll forwards appId', () async {
      final notifier = DesktopNotifier(appId: 'com.x.app');
      await notifier.cancelAll();
      expect(fake.lastMethod, 'cancelAll');
      expect(fake.lastAppId, 'com.x.app');
    });

    test('requestPermission delegates to the platform', () async {
      final notifier = DesktopNotifier();
      expect(await notifier.requestPermission(), isTrue);
      expect(fake.lastMethod, 'requestPermission');
    });

    test('isSupported reflects the platform', () {
      expect(DesktopNotifier().isSupported, isTrue);
    });
  });

  group('UnsupportedDesktopNotifications', () {
    test('reports unsupported and throws on use', () async {
      final platform = UnsupportedDesktopNotifications();
      expect(platform.isSupported, isFalse);
      expect(await platform.requestPermission(), isFalse);
      expect(
        platform.show(NotificationMessage.fromPluginTemplate('i', 't', 'b')),
        throwsA(isA<UnsupportedError>()),
      );
      expect(platform.cancelAll(), throwsA(isA<UnsupportedError>()));
    });
  });
}
