import 'notification_message.dart';
import 'windows_notification_platform_interface.dart';

export 'notification_message.dart';

/// Entry point for sending Windows toast notifications from Flutter.
///
/// Create one instance per AUMID and reuse it.
///
/// ```dart
/// final notifier = WindowsNotification(applicationId: 'com.example.app');
/// await notifier.setCallback((details) { ... });
/// await notifier.showNotificationPluginTemplate(
///   NotificationMessage.fromPluginTemplate('id-1', 'Hi', 'Hello world'),
/// );
/// ```
class WindowsNotification {
  WindowsNotification({this.applicationId});

  /// The Application User Model ID to bind notifications to.
  ///
  /// * Packaged (MSIX) apps: leave null — the OS supplies the AUMID.
  /// * Unpackaged apps: supply an AUMID that you have registered (either via
  ///   a Start Menu shortcut with `System.AppUserModel.ID`, or via a COM
  ///   server for action callbacks). If this value isn't a registered AUMID
  ///   the toast will silently fail to show.
  final String? applicationId;

  /// Show a toast built from one of the plugin's templates. Pass `actions` /
  /// `inputs` on the [message] to attach buttons and input fields.
  Future<void> showNotificationPluginTemplate(NotificationMessage message) =>
      WindowsNotificationPlatform.instance
          .showPluginTemplate(message, applicationId);

  /// Show a toast whose XML you provide. [message] must be built via
  /// [NotificationMessage.fromCustomTemplate].
  Future<void> showNotificationCustomTemplate(
          NotificationMessage message, String template) =>
      WindowsNotificationPlatform.instance
          .showCustomTemplate(message, applicationId, template);

  /// Register a handler for activation and dismissal events. Call this once,
  /// early — typically in `initState` of your root widget. Calling again
  /// replaces the previous callback; pass `null` to stop receiving events.
  Future<void> setCallback(NotificationCallback? callback) async {
    await WindowsNotificationPlatform.instance.init();
    await WindowsNotificationPlatform.instance.setCallback(callback);
  }

  /// Remove every toast this app has posted to the Action Center.
  Future<void> clearNotificationHistory() =>
      WindowsNotificationPlatform.instance
          .clearNotificationHistory(applicationId);

  /// Remove a single toast identified by [id] and [group].
  Future<void> removeNotificationId(String id, String group) {
    if (id.trim().isEmpty || group.trim().isEmpty) {
      throw ArgumentError('id and group must not be empty');
    }
    return WindowsNotificationPlatform.instance
        .removeNotification(id, group, applicationId);
  }

  /// Remove every toast with the given [group] label.
  Future<void> removeNotificationGroup(String group) {
    if (group.trim().isEmpty) {
      throw ArgumentError('group must not be empty');
    }
    return WindowsNotificationPlatform.instance
        .removeNotificationGroup(group, applicationId);
  }

  /// Prepares the plugin for event callbacks. Normally called implicitly by
  /// [setCallback]; exposed for tests.
  Future<void> init() => WindowsNotificationPlatform.instance.init();
}
