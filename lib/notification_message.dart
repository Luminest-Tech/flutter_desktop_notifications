import 'dart:convert';

/// See https://learn.microsoft.com/en-us/uwp/api/windows.ui.notifications.toastdismissalreason
enum NotificationEvent {
  activated,
  dismissedByApp,
  dismissedByUser,
  dismissedByTimeout,
}

enum TemplateType { plugin, custom }

enum NotificationActivationType {
  foreground,
  background,
  protocol,
}

/// Toast scenario. Drives sound, persistence, and special UI treatment.
///
/// * [defaultScenario]: standard toast.
/// * [reminder]: persistent, adds a snooze menu.
/// * [alarm]: persistent with looping sound and built-in Snooze/Dismiss
///   unless you supply your own actions.
/// * [incomingCall]: full-screen call UI on the lock screen.
/// * [urgent]: bypasses Focus Assist (Windows 11+).
enum NotificationScenario {
  defaultScenario,
  reminder,
  alarm,
  incomingCall,
  urgent,
}

enum NotificationDuration { short, long }

/// https://learn.microsoft.com/windows/apps/design/shell/tiles-and-notifications/adaptive-interactive-toasts
enum NotificationTextStyle {
  caption,
  captionSubtle,
  body,
  bodySubtle,
  base,
  baseSubtle,
  subtitle,
  subtitleSubtle,
  title,
  titleSubtle,
  titleNumeral,
  subheader,
  subheaderSubtle,
  subheaderNumeral,
  header,
  headerSubtle,
  headerNumeral,
}

enum NotificationTextAlignment { left, center, right }

enum NotificationButtonStyle { success, critical }

class NotificationSelection {
  const NotificationSelection({required this.id, required this.content});
  final String id;
  final String content;
}

/// A text input or selection list shown inside a toast. Link to an action
/// button with [NotificationAction.inputId] to get a send-reply pairing.
class NotificationInput {
  const NotificationInput.text({
    required this.id,
    this.title,
    this.placeholder,
  })  : type = 'text',
        selections = const [],
        defaultSelectionId = null;

  const NotificationInput.selection({
    required this.id,
    required this.selections,
    this.title,
    this.defaultSelectionId,
  })  : type = 'selection',
        placeholder = null;

  final String id;
  final String type;
  final String? title;
  final String? placeholder;
  final List<NotificationSelection> selections;
  final String? defaultSelectionId;
}

/// Rendered as a button by default. Set [contextMenu] to put it under the
/// toast's overflow menu instead.
class NotificationAction {
  const NotificationAction({
    required this.content,
    required this.arguments,
    this.activationType = NotificationActivationType.foreground,
    this.imageUri,
    this.inputId,
    this.buttonStyle,
    this.contextMenu = false,
  });

  final String content;
  final String arguments;
  final NotificationActivationType activationType;
  final String? imageUri;
  final String? inputId;
  final NotificationButtonStyle? buttonStyle;
  final bool contextMenu;
}

class NotificationText {
  const NotificationText(
    this.content, {
    this.style,
    this.alignment,
    this.maxLines,
  });
  final String content;
  final NotificationTextStyle? style;
  final NotificationTextAlignment? alignment;
  final int? maxLines;
}

/// Names mirror the ms-winsoundevent source strings so emission can use
/// `.name` directly.
// ignore_for_file: constant_identifier_names
enum NotificationSound {
  Default,
  IM,
  Mail,
  Reminder,
  SMS,
  Alarm,
  Alarm2,
  Alarm3,
  Alarm4,
  Alarm5,
  Alarm6,
  Alarm7,
  Alarm8,
  Alarm9,
  Alarm10,
  Call,
  Call2,
  Call3,
  Call4,
  Call5,
  Call6,
  Call7,
  Call8,
  Call9,
  Call10,
}

/// [loop] only works for Alarm / Call sounds, and only with a long-duration
/// toast or an alarm/incomingCall scenario.
class NotificationAudio {
  const NotificationAudio({
    this.sound,
    this.silent = false,
    this.loop = false,
  }) : _custom = null;

  const NotificationAudio.silent()
      : sound = null,
        silent = true,
        loop = false,
        _custom = null;

  const NotificationAudio.custom(String source, {this.loop = false})
      : sound = null,
        silent = false,
        _custom = source;

  final NotificationSound? sound;
  final bool silent;
  final bool loop;
  final String? _custom;

  String? get sourceUri {
    if (_custom != null) return _custom;
    if (sound == null) return null;
    return 'ms-winsoundevent:Notification.${sound!.name}';
  }
}

/// [value] is `null` for indeterminate, otherwise clamped to `[0.0, 1.0]`.
class NotificationProgress {
  const NotificationProgress({
    this.title,
    this.value,
    this.valueStringOverride,
    this.status = '',
  });

  final String? title;
  final double? value;

  /// Replaces the default `35%` readout. e.g. `'12 of 34'`.
  final String? valueStringOverride;

  final String status;
}

class NotificationMessage {
  NotificationMessage.fromPluginTemplate(
    this.id,
    String this.title,
    String this.body, {
    this.image,
    this.largeImage,
    this.heroImage,
    this.extraTexts = const [],
    this.attribution,
    this.launch,
    this.group,
    this.payload = const {},
    this.actions = const [],
    this.inputs = const [],
    this.audio,
    this.progress,
    this.scenario,
    this.duration,
    this.activationType,
    this.displayTimestamp,
  }) : templateType = TemplateType.plugin {
    assert(id.trim().isNotEmpty, 'id must not be empty');
    assert(group == null || group!.trim().isNotEmpty,
        'group must not be empty when provided');
  }

  NotificationMessage.fromCustomTemplate(
    this.id, {
    this.group,
    this.launch,
    this.payload = const {},
  })  : templateType = TemplateType.custom,
        title = null,
        body = null,
        image = null,
        largeImage = null,
        heroImage = null,
        extraTexts = const [],
        attribution = null,
        actions = const [],
        inputs = const [],
        audio = null,
        progress = null,
        scenario = null,
        duration = null,
        activationType = null,
        displayTimestamp = null {
    assert(id.trim().isNotEmpty, 'id must not be empty');
    assert(group == null || group!.trim().isNotEmpty,
        'group must not be empty when provided');
  }

  NotificationMessage._fromJson(Map<String, dynamic> json)
      : id = json['tag'] as String,
        title = json['title'] as String?,
        body = json['body'] as String?,
        image = json['image'] as String?,
        largeImage = json['largeImage'] as String?,
        heroImage = json['heroImage'] as String?,
        extraTexts = const [],
        attribution = json['attribution'] as String?,
        group = json['group'] as String?,
        launch = json['launch'] as String?,
        payload = Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
        templateType = TemplateType.values
            .firstWhere((e) => e.name == json['templateType']),
        actions = const [],
        inputs = const [],
        audio = null,
        progress = null,
        scenario = null,
        duration = null,
        activationType = null,
        displayTimestamp = null;

  final String id;
  final TemplateType templateType;
  final String? title;
  final String? body;
  final String? image;
  final String? largeImage;
  final String? heroImage;
  final List<NotificationText> extraTexts;
  final String? attribution;
  final String? group;
  final String? launch;
  final Map<String, dynamic> payload;
  final List<NotificationAction> actions;
  final List<NotificationInput> inputs;
  final NotificationAudio? audio;
  final NotificationProgress? progress;
  final NotificationScenario? scenario;
  final NotificationDuration? duration;

  /// Activation for clicks on the toast body itself. Defaults to
  /// [NotificationActivationType.foreground]; set to `protocol` when [launch]
  /// is a URL you want Windows to open.
  final NotificationActivationType? activationType;

  final DateTime? displayTimestamp;

  Map<String, dynamic> toPayloadMap() => {
        'title': title,
        'body': body,
        'tag': id,
        'image': image,
        'largeImage': largeImage,
        'heroImage': heroImage,
        'attribution': attribution,
        'group': group,
        'launch': launch,
        'templateType': templateType.name,
        'payload': payload,
      };

  factory NotificationMessage.fromCallbackPayload(String encoded) =>
      NotificationMessage._fromJson(
          json.decode(encoded) as Map<String, dynamic>);
}

typedef NotificationCallback = void Function(
    NotificationCallbackDetails details);

class NotificationCallbackDetails {
  const NotificationCallbackDetails({
    required this.event,
    required this.message,
    required this.arguments,
    required this.userInput,
  });

  final NotificationEvent event;
  final NotificationMessage message;

  /// `arguments` from the activated `<action>`, or the toast's `launch`
  /// value for body taps. Null on dismissal events.
  final String? arguments;

  final Map<String, String> userInput;
}
