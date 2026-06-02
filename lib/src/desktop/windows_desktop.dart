import '../../notification_message.dart';
import '../../windows_notification_platform_interface.dart';
import 'desktop_notifications_platform.dart';

/// Windows implementation of [DesktopNotificationsPlatform]. Delegates to the
/// existing WinRT toast path, so the full plugin-template feature set is
/// available through the unified API too.
///
/// Registered automatically via the `windows.dartPluginClass` pubspec entry.
class WindowsDesktopNotifications extends DesktopNotificationsPlatform {
  /// Called by the generated plugin registrant on Windows.
  static void registerWith() {
    DesktopNotificationsPlatform.instance = WindowsDesktopNotifications();
  }

  WindowsNotificationPlatform get _win => WindowsNotificationPlatform.instance;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> show(NotificationMessage message,
          {String? appName, String? appId}) =>
      _win.showPluginTemplate(message, appId);

  @override
  Future<void> setHandler(NotificationCallback? handler) async {
    await _win.init();
    await _win.setCallback(handler);
  }

  @override
  Future<void> cancel(String id, {String? group, String? appId}) =>
      _win.removeNotification(id, group ?? '', appId);

  @override
  Future<void> cancelAll({String? appId}) =>
      _win.clearNotificationHistory(appId);
}
