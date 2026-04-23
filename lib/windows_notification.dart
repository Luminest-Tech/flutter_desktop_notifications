import 'notification_message.dart';
import 'windows_notification_platform_interface.dart';

export 'notification_message.dart';
export 'widget_to_image.dart';

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

  /// Register [aumid] with Windows so toasts posted under it show your
  /// [displayName] and icon instead of a generic or borrowed sender.
  ///
  /// Creates (or updates) a Start Menu shortcut at
  /// `%APPDATA%\Microsoft\Windows\Start Menu\Programs\{displayName}.lnk`
  /// that points at the running executable, with `System.AppUserModel.ID`
  /// set to [aumid]. Idempotent — safe to call on every launch.
  ///
  /// [iconPath] is an optional path to a `.ico` file. If omitted, Windows
  /// uses the icon embedded in your exe.
  ///
  /// Only meaningful for **unpackaged** apps. Packaged (MSIX) apps should
  /// leave [WindowsNotification.applicationId] null and let the manifest
  /// supply the AUMID — calling this from a packaged app is a no-op at
  /// best and may fail.
  ///
  /// The [aumid] must be a valid AUMID: non-empty, ≤ 129 chars, no spaces.
  /// Microsoft recommends `CompanyName.ProductName.SubProduct.VersionInformation`.
  /// Raise this app's window to the foreground and restore it from minimized.
  ///
  /// Useful from a notification callback — when the user clicks an "Open"
  /// action button on a toast, your handler can call this to bring the
  /// already-running app window forward. Windows may refuse the foreground
  /// switch if the calling process doesn't currently own focus (a system
  /// anti-focus-steal rule); the window will at least be un-minimized.
  static Future<void> bringAppToForeground() =>
      WindowsNotificationPlatform.instance.bringAppToForeground();

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
      throw ArgumentError.value(
          aumid, 'aumid', 'must not contain whitespace');
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
