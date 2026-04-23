import 'dart:convert';

/// Why a notification was dismissed, or that it was activated.
///
/// See https://learn.microsoft.com/en-us/uwp/api/windows.ui.notifications.toastdismissalreason
enum NotificationEvent {
  /// The user clicked the toast body or an action button that uses foreground
  /// or protocol activation.
  activated,

  /// The app explicitly hid the toast by calling `ToastNotifier.Hide`.
  dismissedByApp,

  /// The user closed the toast.
  dismissedByUser,

  /// The toast timed out (7s normal, 25s long-duration).
  dismissedByTimeout,
}

enum TemplateType { plugin, custom }

/// How an action button — or the toast body itself — activates the app.
enum NotificationActivationType {
  /// Opens the app in the foreground with the action's arguments.
  foreground,

  /// Invokes a background task (packaged apps only).
  background,

  /// Launches a protocol URI (e.g. `https://…` or `myapp://…`).
  protocol,
}

/// Toast scenario — drives sound, persistence, and special UI treatment.
///
/// - [defaultScenario]: standard toast, auto-dismisses after [NotificationDuration.short].
/// - [reminder]: persistent until the user dismisses it, offers a snooze menu.
/// - [alarm]: persistent, louder/looping sound, built-in Snooze/Dismiss buttons
///   unless you supply your own `<action>` elements.
/// - [incomingCall]: full-screen call UI on lock screen, looping ringtone.
/// - [urgent]: bypasses Focus Assist (Windows 11+).
enum NotificationScenario {
  defaultScenario,
  reminder,
  alarm,
  incomingCall,
  urgent,
}

enum NotificationDuration { short, long }

/// Built-in text styles Windows renders for ToastGeneric bindings.
/// See https://learn.microsoft.com/windows/apps/design/shell/tiles-and-notifications/adaptive-interactive-toasts
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

/// Visual emphasis for an action button.
enum NotificationButtonStyle { success, critical }

/// A selectable item inside a [NotificationInput.selection].
class NotificationSelection {
  const NotificationSelection({required this.id, required this.content});
  final String id;
  final String content;
}

/// An input field shown inside a toast: either a free-form text box or a
/// selection list. Associate with an action button via [NotificationAction.inputId].
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

/// An action. Rendered as a button by default; pass [contextMenu] = true to
/// put it under the toast's `…` overflow menu instead.
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

/// Structured text line in the toast body. A plain string works too
/// (implicitly uses defaults), but use [NotificationText] when you need
/// styling or alignment.
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

/// Named system sounds. Supply to [NotificationAudio.sound]. For arbitrary
/// audio files, construct with [NotificationAudio.custom].
///
/// Enum names intentionally mirror the ms-winsoundevent source names
/// (`Notification.Default`, `Notification.IM`, etc.), so emission doesn't
/// need a translation table.
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

/// Audio behavior for the toast. [silent] suppresses any sound.
/// [loop] keeps the sound playing for the duration of the toast — only valid
/// for Alarm/Call family sounds and requires a long-duration toast or a
/// scenario like `alarm` / `incomingCall`.
class NotificationAudio {
  const NotificationAudio({
    this.sound,
    this.silent = false,
    this.loop = false,
  }) : _custom = null;

  /// Silent toast — no sound at all.
  const NotificationAudio.silent()
      : sound = null,
        silent = true,
        loop = false,
        _custom = null;

  /// Use a custom ms-winsoundevent or file-URI source. Rarely needed; prefer
  /// [NotificationAudio.new] with [NotificationSound].
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

/// A progress bar rendered below the text of the toast.
///
/// [value] must be in `[0.0, 1.0]` or `null` for indeterminate.
class NotificationProgress {
  const NotificationProgress({
    this.title,
    this.value,
    this.valueStringOverride,
    this.status = '',
  });

  final String? title;

  /// `null` → indeterminate; otherwise clamped to `[0.0, 1.0]`.
  final double? value;

  /// Text shown in place of the default `35%` readout — e.g. `"12 of 34"`.
  final String? valueStringOverride;

  /// Small line of text below the progress bar (e.g. `"Uploading…"`).
  final String status;
}

class NotificationMessage {
  /// Build a toast from the plugin's built-in template.
  ///
  /// [title] and [body] populate the two primary text lines. Everything else
  /// is optional. See [NotificationAction] / [NotificationInput] for buttons
  /// and reply boxes; [NotificationAudio] / [NotificationProgress] /
  /// [NotificationScenario] etc. for the richer features.
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

  /// Controls how clicking the toast body itself activates the app.
  ///
  /// Defaults to [NotificationActivationType.foreground] for plugin
  /// templates — clicking fires an `activated` event with [launch] as the
  /// arguments string. Set to [NotificationActivationType.protocol] when
  /// [launch] is a URL you want Windows to open.
  final NotificationActivationType? activationType;

  /// If set, overrides the "when" timestamp shown in the Action Center.
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

  /// `arguments` attribute from the activated `<action>`, or the toast's
  /// `launch` value if the body itself was tapped. Null for dismissal events.
  final String? arguments;

  final Map<String, String> userInput;
}
