import 'package:desktop_notifications/desktop_notifications.dart' as dn;

import '../../notification_message.dart';
import 'desktop_notifications_platform.dart';

/// Linux implementation of [DesktopNotificationsPlatform], built on the
/// freedesktop D-Bus notification spec via the `desktop_notifications` package.
///
/// Registered automatically via the `linux.dartPluginClass` pubspec entry. No
/// native code; it talks to `org.freedesktop.Notifications` directly.
class LinuxDesktopNotifications extends DesktopNotificationsPlatform {
  /// Called by the generated plugin registrant on Linux.
  static void registerWith() {
    DesktopNotificationsPlatform.instance = LinuxDesktopNotifications();
  }

  dn.NotificationsClient? _client;
  NotificationCallback? _handler;

  /// Our string id -> the live D-Bus notification, for replace and cancel.
  final Map<String, dn.Notification> _live = {};

  dn.NotificationsClient get _bus => _client ??= dn.NotificationsClient();

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> show(NotificationMessage message,
      {String? appName, String? appId}) async {
    final actions = <dn.NotificationAction>[
      // The "default" action fires on a click of the notification body.
      const dn.NotificationAction('default', ''),
      for (final a in message.actions)
        dn.NotificationAction(a.arguments, a.content),
    ];

    final notification = await _bus.notify(
      message.title ?? '',
      body: message.body ?? '',
      appName: appName ?? '',
      appIcon: _icon(message) ?? '',
      replacesId: _live[message.id]?.id ?? 0,
      expireTimeoutMs: message.duration == NotificationDuration.long ? 0 : -1,
      hints: [dn.NotificationHint.urgency(_urgency(message.scenario))],
      actions: actions,
    );

    _live[message.id] = notification;
    _wireEvents(message, notification);
  }

  void _wireEvents(NotificationMessage message, dn.Notification notification) {
    var handled = false;

    notification.action.then((key) {
      if (handled) return;
      handled = true;
      _live.remove(message.id);
      _handler?.call(NotificationCallbackDetails(
        event: NotificationEvent.activated,
        message: message,
        arguments: key == 'default' ? message.launch : key,
        userInput: const {},
      ));
    });

    notification.closeReason.then((reason) {
      if (handled) return;
      handled = true;
      _live.remove(message.id);
      _handler?.call(NotificationCallbackDetails(
        event: _closeEvent(reason),
        message: message,
        arguments: null,
        userInput: const {},
      ));
    });
  }

  @override
  Future<void> setHandler(NotificationCallback? handler) async {
    _handler = handler;
  }

  @override
  Future<void> cancel(String id, {String? group, String? appId}) async {
    await _live.remove(id)?.close();
  }

  @override
  Future<void> cancelAll({String? appId}) async {
    final open = _live.values.toList();
    _live.clear();
    for (final n in open) {
      await n.close();
    }
  }

  static String? _icon(NotificationMessage m) =>
      m.image ?? m.largeImage ?? m.heroImage;

  static dn.NotificationUrgency _urgency(NotificationScenario? s) {
    switch (s) {
      case NotificationScenario.urgent:
      case NotificationScenario.incomingCall:
        return dn.NotificationUrgency.critical;
      case NotificationScenario.alarm:
      case NotificationScenario.reminder:
      case NotificationScenario.defaultScenario:
      case null:
        return dn.NotificationUrgency.normal;
    }
  }

  static NotificationEvent _closeEvent(dn.NotificationClosedReason reason) {
    switch (reason) {
      case dn.NotificationClosedReason.expired:
        return NotificationEvent.dismissedByTimeout;
      case dn.NotificationClosedReason.closed:
        return NotificationEvent.dismissedByApp;
      case dn.NotificationClosedReason.dismissed:
      case dn.NotificationClosedReason.unknown:
        return NotificationEvent.dismissedByUser;
    }
  }
}
