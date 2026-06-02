import 'package:flutter/services.dart';

import '../../notification_message.dart';
import 'desktop_notifications_platform.dart';

/// macOS implementation of [DesktopNotificationsPlatform], backed by
/// `UNUserNotificationCenter` in the Swift plugin.
///
/// Registered automatically via the `macos.dartPluginClass` pubspec entry.
class MacosDesktopNotifications extends DesktopNotificationsPlatform {
  /// Called by the generated plugin registrant on macOS.
  static void registerWith() {
    DesktopNotificationsPlatform.instance = MacosDesktopNotifications();
  }

  static const MethodChannel _channel =
      MethodChannel('flutter_desktop_notifications/macos');

  /// Shown messages, kept so a callback can hand back the original message.
  final Map<String, NotificationMessage> _shown = {};
  NotificationCallback? _handler;
  bool _attached = false;

  @override
  Future<bool> requestPermission() async {
    final granted = await _channel.invokeMethod<bool>('requestPermission');
    return granted ?? false;
  }

  @override
  Future<void> show(NotificationMessage message,
      {String? appName, String? appId}) async {
    _shown[message.id] = message;

    final actions = <Map<String, dynamic>>[];
    for (final a in message.actions) {
      final input = a.inputId == null
          ? null
          : message.inputs.cast<NotificationInput?>().firstWhere(
                (i) => i?.id == a.inputId,
                orElse: () => null,
              );
      actions.add({
        'id': a.arguments,
        'title': a.content,
        'textInput': input != null,
        if (input?.placeholder != null) 'placeholder': input!.placeholder,
      });
    }

    await _channel.invokeMethod('show', {
      'id': message.id,
      'title': message.title ?? '',
      if (_subtitle(message) != null) 'subtitle': _subtitle(message),
      'body': message.body ?? '',
      if (_imagePath(message) != null) 'image': _imagePath(message),
      if (message.group != null) 'threadId': message.group,
      'sound': message.audio?.silent == true ? 'none' : 'default',
      'interruptionLevel': _interruptionLevel(message.scenario),
      'actions': actions,
    });
  }

  @override
  Future<void> setHandler(NotificationCallback? handler) async {
    _handler = handler;
    if (_attached) return;
    _attached = true;
    _channel.setMethodCallHandler(_onNative);
  }

  @override
  Future<void> cancel(String id, {String? group, String? appId}) async {
    _shown.remove(id);
    await _channel.invokeMethod('cancel', {'id': id});
  }

  @override
  Future<void> cancelAll({String? appId}) async {
    _shown.clear();
    await _channel.invokeMethod('cancelAll');
  }

  Future<dynamic> _onNative(MethodCall call) async {
    if (call.method != 'onEvent') return;
    final cb = _handler;
    if (cb == null) return;

    final args = Map<String, dynamic>.from(call.arguments as Map);
    final id = args['id'] as String? ?? '';
    final message = _shown[id] ??
        NotificationMessage.fromPluginTemplate(id.isEmpty ? '?' : id, '', '');

    if (args['event'] == 'activated') {
      final actionId = args['actionId'] as String?;
      final reply = args['reply'] as String?;
      final userInput = <String, String>{};
      if (reply != null) {
        final inputId = _inputIdFor(message, actionId);
        if (inputId != null) userInput[inputId] = reply;
      }
      cb(NotificationCallbackDetails(
        event: NotificationEvent.activated,
        message: message,
        arguments: actionId == 'default' ? message.launch : actionId,
        userInput: userInput,
      ));
    } else {
      _shown.remove(id);
      cb(NotificationCallbackDetails(
        event: NotificationEvent.dismissedByUser,
        message: message,
        arguments: null,
        userInput: const {},
      ));
    }
  }

  static String? _inputIdFor(NotificationMessage message, String? actionId) {
    for (final a in message.actions) {
      if (a.arguments == actionId) return a.inputId;
    }
    return null;
  }

  static String? _subtitle(NotificationMessage m) {
    if (m.extraTexts.isNotEmpty) return m.extraTexts.first.content;
    return m.attribution;
  }

  static String? _imagePath(NotificationMessage m) =>
      m.heroImage ?? m.largeImage ?? m.image;

  static String _interruptionLevel(NotificationScenario? s) {
    switch (s) {
      case NotificationScenario.urgent:
      case NotificationScenario.incomingCall:
        return 'timeSensitive';
      case NotificationScenario.alarm:
      case NotificationScenario.reminder:
      case NotificationScenario.defaultScenario:
      case null:
        return 'active';
    }
  }
}
