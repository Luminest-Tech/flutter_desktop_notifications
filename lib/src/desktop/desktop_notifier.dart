import '../../notification_message.dart';
import 'desktop_notifications_platform.dart';

/// One notifier for Windows, macOS, and Linux.
///
/// It speaks the common subset every desktop supports: a title and body, an
/// icon or image, action buttons, a reply field (Windows and macOS), urgency,
/// and activation/dismissal callbacks. Build the message with
/// [NotificationMessage.fromPluginTemplate]; each platform renders the fields
/// it understands and ignores the rest.
///
/// ```dart
/// final notifier = DesktopNotifier(appName: 'My App', appId: 'com.example.app');
/// await notifier.requestPermission();
/// await notifier.setCallback((details) {
///   if (details.event == NotificationEvent.activated) {
///     // details.arguments, details.userInput['reply'], details.message...
///   }
/// });
/// await notifier.show(
///   NotificationMessage.fromPluginTemplate('msg-1', 'Hi', 'Hello from any desktop'),
/// );
/// ```
///
/// For Windows-only features (scenarios, looping audio, progress bars, custom
/// toast XML, hero-image-from-widget, AUMID registration) use
/// `WindowsNotification` directly.
class DesktopNotifier {
  DesktopNotifier({this.appName, this.appId});

  /// Sender name shown on Linux (the D-Bus `app_name`). Ignored elsewhere.
  final String? appName;

  /// Windows AUMID this notifier's notifications bind to. Ignored elsewhere.
  final String? appId;

  DesktopNotificationsPlatform get _platform =>
      DesktopNotificationsPlatform.instance;

  /// Whether the current platform is one of Windows, macOS, or Linux.
  bool get isSupported => _platform.isSupported;

  /// Requests notification permission. Only macOS prompts; the others return
  /// true. Call once at startup before [show].
  Future<bool> requestPermission() => _platform.requestPermission();

  /// Posts [message].
  Future<void> show(NotificationMessage message) =>
      _platform.show(message, appName: appName, appId: appId);

  /// Registers (or clears, when null) the activation/dismissal handler.
  Future<void> setCallback(NotificationCallback? handler) =>
      _platform.setHandler(handler);

  /// Removes one delivered notification by id, plus [group] on Windows.
  Future<void> cancel(String id, {String? group}) =>
      _platform.cancel(id, group: group, appId: appId);

  /// Removes every notification this app has delivered.
  Future<void> cancelAll() => _platform.cancelAll(appId: appId);
}
