import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_message.dart';
import 'src/toast_xml.dart';
import 'windows_notification_platform_interface.dart';

class MethodChannelWindowsNotification extends WindowsNotificationPlatform {
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('windows_notification');

  NotificationCallback? _callback;
  bool _handlerAttached = false;

  @override
  Future<void> init() async {
    await methodChannel.invokeMethod('init');
  }

  @override
  Future<void> registerAumid({
    required String aumid,
    required String displayName,
    String? iconPath,
  }) async {
    final args = <String, dynamic>{
      'aumid': aumid,
      'display_name': displayName,
    };
    if (iconPath != null) args['icon_path'] = iconPath;
    await methodChannel.invokeMethod('register_aumid', args);
  }

  @override
  Future<void> bringAppToForeground() async {
    await methodChannel.invokeMethod('bring_to_front');
  }

  @override
  Future<void> showPluginTemplate(
      NotificationMessage message, String? applicationId) async {
    assert(message.templateType == TemplateType.plugin,
        'showPluginTemplate requires a message built with fromPluginTemplate');
    final xml = buildPluginTemplateXml(message);
    await _showToast(message, applicationId, xml);
  }

  @override
  Future<void> showCustomTemplate(NotificationMessage message,
      String? applicationId, String template) async {
    assert(message.templateType == TemplateType.custom,
        'showCustomTemplate requires a message built with fromCustomTemplate');
    await _showToast(message, applicationId, template);
  }

  Future<void> _showToast(NotificationMessage message, String? applicationId,
      String template) async {
    final args = <String, dynamic>{
      'tag': message.id,
      'template': template,
      'payload': json.encode(message.toPayloadMap()),
    };
    if (message.group != null) args['group'] = message.group;
    if (message.launch != null) args['launch'] = message.launch;
    if (applicationId != null) args['application_id'] = applicationId;
    await methodChannel.invokeMethod('show_toast', args);
  }

  @override
  Future<void> clearNotificationHistory(String? applicationId) async {
    final args = <String, dynamic>{};
    if (applicationId != null) args['application_id'] = applicationId;
    await methodChannel.invokeMethod('clear_history', args);
  }

  @override
  Future<void> removeNotification(
      String id, String group, String? applicationId) async {
    final args = <String, dynamic>{'tag': id, 'group': group};
    if (applicationId != null) args['application_id'] = applicationId;
    await methodChannel.invokeMethod('remove_notification', args);
  }

  @override
  Future<void> removeNotificationGroup(
      String group, String? applicationId) async {
    final args = <String, dynamic>{'group': group};
    if (applicationId != null) args['application_id'] = applicationId;
    await methodChannel.invokeMethod('remove_group', args);
  }

  @override
  Future<void> setCallback(NotificationCallback? callback) async {
    _callback = callback;
    if (_handlerAttached) return;
    _handlerAttached = true;
    methodChannel.setMethodCallHandler(_handleCallbackFromNative);
  }

  Future<void> _handleCallbackFromNative(MethodCall call) async {
    final cb = _callback;
    if (cb == null) return;
    final event = _eventFromWireName(call.method);
    if (event == null) return;

    final args = Map<String, dynamic>.from(call.arguments as Map);
    final payloadJson = args['payload'] as String? ?? '{}';
    NotificationMessage message;
    try {
      message = NotificationMessage.fromCallbackPayload(payloadJson);
    } catch (_) {
      return;
    }

    cb(NotificationCallbackDetails(
      event: event,
      message: message,
      arguments: args['arguments'] as String?,
      userInput: Map<String, String>.from(args['user_input'] as Map? ?? {}),
    ));
  }

  static NotificationEvent? _eventFromWireName(String wire) {
    for (final e in NotificationEvent.values) {
      if (e.name == wire) return e;
    }
    return null;
  }
}
