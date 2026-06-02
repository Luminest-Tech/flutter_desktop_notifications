import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'notification_message.dart';
import 'windows_notification_method_channel.dart';

abstract class WindowsNotificationPlatform extends PlatformInterface {
  WindowsNotificationPlatform() : super(token: _token);

  static final Object _token = Object();

  static WindowsNotificationPlatform _instance =
      MethodChannelWindowsNotification();

  static WindowsNotificationPlatform get instance => _instance;

  static set instance(WindowsNotificationPlatform value) {
    PlatformInterface.verifyToken(value, _token);
    _instance = value;
  }

  Future<void> init() =>
      throw UnimplementedError('init() has not been implemented.');

  Future<void> registerAumid({
    required String aumid,
    required String displayName,
    String? iconPath,
  }) =>
      throw UnimplementedError('registerAumid() has not been implemented.');

  Future<void> bringAppToForeground() => throw UnimplementedError(
      'bringAppToForeground() has not been implemented.');

  Future<void> showPluginTemplate(
          NotificationMessage message, String? applicationId) =>
      throw UnimplementedError(
          'showPluginTemplate() has not been implemented.');

  Future<void> showCustomTemplate(NotificationMessage message,
          String? applicationId, String template) =>
      throw UnimplementedError(
          'showCustomTemplate() has not been implemented.');

  Future<void> setCallback(NotificationCallback? callback) =>
      throw UnimplementedError('setCallback() has not been implemented.');

  Future<void> clearNotificationHistory(String? applicationId) =>
      throw UnimplementedError(
          'clearNotificationHistory() has not been implemented.');

  Future<void> removeNotification(
          String id, String group, String? applicationId) =>
      throw UnimplementedError(
          'removeNotification() has not been implemented.');

  Future<void> removeNotificationGroup(String group, String? applicationId) =>
      throw UnimplementedError(
          'removeNotificationGroup() has not been implemented.');
}
