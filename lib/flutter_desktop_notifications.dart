import 'notification_message.dart';
import 'windows_notification_platform_interface.dart';

export 'notification_message.dart';
export 'widget_to_image.dart';

// Cross-platform unified API.
export 'src/desktop/desktop_notifier.dart';
export 'src/desktop/desktop_notifications_platform.dart';
// Platform implementations. Exported so the generated plugin registrant can
// resolve each `dartPluginClass` from the package's main library.
export 'src/desktop/windows_desktop.dart';
export 'src/desktop/macos_desktop.dart';
export 'src/desktop/linux_desktop.dart';

/// ```dart
/// final notifier = WindowsNotification(applicationId: 'com.example.app');
/// await notifier.setCallback((details) { ... });
/// await notifier.showNotificationPluginTemplate(
///   NotificationMessage.fromPluginTemplate('id-1', 'Hi', 'Hello world'),
/// );
/// ```
class WindowsNotification {
  WindowsNotification({this.applicationId});

  /// AUMID this instance binds its toasts to.
  ///
  /// Leave null for packaged apps. For unpackaged apps, supply an AUMID
  /// registered via a Start Menu shortcut (see [registerAumid]) or a COM
  /// server. An unregistered AUMID causes toasts to silently fail.
  final String? applicationId;

  Future<void> showNotificationPluginTemplate(NotificationMessage message) =>
      WindowsNotificationPlatform.instance
          .showPluginTemplate(message, applicationId);

  /// [message] must be built via [NotificationMessage.fromCustomTemplate].
  Future<void> showNotificationCustomTemplate(
          NotificationMessage message, String template) =>
      WindowsNotificationPlatform.instance
          .showCustomTemplate(message, applicationId, template);

  /// Calling again replaces the previous handler. Pass null to stop
  /// receiving events.
  Future<void> setCallback(NotificationCallback? callback) async {
    await WindowsNotificationPlatform.instance.init();
    await WindowsNotificationPlatform.instance.setCallback(callback);
  }

  Future<void> clearNotificationHistory() =>
      WindowsNotificationPlatform.instance
          .clearNotificationHistory(applicationId);

  Future<void> removeNotificationId(String id, String group) {
    if (id.trim().isEmpty || group.trim().isEmpty) {
      throw ArgumentError('id and group must not be empty');
    }
    return WindowsNotificationPlatform.instance
        .removeNotification(id, group, applicationId);
  }

  Future<void> removeNotificationGroup(String group) {
    if (group.trim().isEmpty) {
      throw ArgumentError('group must not be empty');
    }
    return WindowsNotificationPlatform.instance
        .removeNotificationGroup(group, applicationId);
  }

  Future<void> init() => WindowsNotificationPlatform.instance.init();

  /// Raises this app's window and restores it from minimized.
  ///
  /// Intended for "Open" actions fired from a notification callback.
  /// Windows may refuse the foreground switch when the process doesn't own
  /// focus, in which case the window still un-minimizes.
  static Future<void> bringAppToForeground() =>
      WindowsNotificationPlatform.instance.bringAppToForeground();

  /// Writes a Start Menu shortcut at
  /// `%APPDATA%\Microsoft\Windows\Start Menu\Programs\{displayName}.lnk`
  /// pointing at the running executable with `System.AppUserModel.ID` set
  /// to [aumid]. Idempotent.
  ///
  /// Call once at startup for unpackaged apps so Windows shows toasts under
  /// your app's name and icon instead of a generic or borrowed sender. If
  /// [iconPath] is omitted, Windows uses the icon embedded in the exe.
  ///
  /// AUMID rules: non-empty, 129 chars or fewer, no whitespace. Microsoft
  /// recommends `CompanyName.ProductName.SubProduct.VersionInformation`.
  static Future<void> registerAumid({
    required String aumid,
    required String displayName,
    String? iconPath,
  }) {
    if (aumid.isEmpty) {
      throw ArgumentError.value(aumid, 'aumid', 'must not be empty');
    }
    if (aumid.length > 129) {
      throw ArgumentError.value(
          aumid, 'aumid', 'must be 129 characters or fewer');
    }
    if (aumid.contains(' ')) {
      throw ArgumentError.value(aumid, 'aumid', 'must not contain whitespace');
    }
    if (displayName.trim().isEmpty) {
      throw ArgumentError.value(
          displayName, 'displayName', 'must not be empty');
    }
    return WindowsNotificationPlatform.instance.registerAumid(
      aumid: aumid,
      displayName: displayName,
      iconPath: iconPath,
    );
  }
}
