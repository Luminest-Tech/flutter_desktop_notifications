import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../notification_message.dart';

/// The cross-platform surface behind [DesktopNotifier].
///
/// Each desktop platform registers its own implementation at startup via the
/// `dartPluginClass` entries in `pubspec.yaml`. On a platform with no
/// implementation (mobile, web, the plain Dart VM in tests), the default
/// [UnsupportedDesktopNotifications] instance is used and [isSupported] is
/// false.
abstract class DesktopNotificationsPlatform extends PlatformInterface {
  DesktopNotificationsPlatform() : super(token: _token);

  static final Object _token = Object();

  static DesktopNotificationsPlatform _instance =
      UnsupportedDesktopNotifications();

  static DesktopNotificationsPlatform get instance => _instance;

  static set instance(DesktopNotificationsPlatform value) {
    PlatformInterface.verifyToken(value, _token);
    _instance = value;
  }

  /// Whether the current platform has a working implementation.
  bool get isSupported => true;

  /// Asks the OS for permission to post notifications. Only macOS actually
  /// prompts; Windows and Linux resolve to true. Call once before [show].
  Future<bool> requestPermission() async => true;

  /// Posts [message]. Platforms render the fields they support and ignore the
  /// rest. [appName] is shown as the sender on Linux; [appId] is the Windows
  /// AUMID.
  Future<void> show(NotificationMessage message,
      {String? appName, String? appId});

  /// Registers a single handler for activation and dismissal events. Pass null
  /// to stop receiving them.
  Future<void> setHandler(NotificationCallback? handler);

  /// Removes a delivered notification by id (and [group] where the platform
  /// uses one).
  Future<void> cancel(String id, {String? group, String? appId});

  /// Removes every notification this app has delivered.
  Future<void> cancelAll({String? appId});
}

/// Fallback used on platforms without an implementation.
class UnsupportedDesktopNotifications extends DesktopNotificationsPlatform {
  @override
  bool get isSupported => false;

  @override
  Future<bool> requestPermission() async => false;

  Never _unsupported() => throw UnsupportedError(
      'flutter_desktop_notifications has no implementation for this platform. '
      'Supported: Windows, macOS, Linux.');

  @override
  Future<void> show(NotificationMessage message,
          {String? appName, String? appId}) async =>
      _unsupported();

  @override
  Future<void> setHandler(NotificationCallback? handler) async =>
      _unsupported();

  @override
  Future<void> cancel(String id, {String? group, String? appId}) async =>
      _unsupported();

  @override
  Future<void> cancelAll({String? appId}) async => _unsupported();
}
