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

/// How an action button activates the app when tapped.
enum NotificationActivationType {
  /// Opens the app in the foreground with the action's arguments.
  foreground,

  /// Invokes a background task (packaged apps only).
  background,

  /// Launches a protocol URI (e.g. `myapp://open?id=1`).
  protocol,
}

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
  /// A free-form text input (reply box).
  const NotificationInput.text({
    required this.id,
    this.title,
    this.placeholder,
  })  : type = 'text',
        selections = const [],
        defaultSelectionId = null;

  /// A selection list. Provide [selections]; optionally pre-select one with
  /// [defaultSelectionId].
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

/// An action button at the bottom of a toast.
class NotificationAction {
  const NotificationAction({
    required this.content,
    required this.arguments,
    this.activationType = NotificationActivationType.foreground,
    this.imageUri,
    this.inputId,
    this.buttonStyle,
  });

  /// The label shown on the button.
  final String content;

  /// App-defined string passed back via [NotificationCallbackDetails.arguments].
  final String arguments;

  final NotificationActivationType activationType;

  /// Optional icon for the button.
  final String? imageUri;

  /// If set, renders this action next to the matching [NotificationInput] so
  /// it becomes a reply-send button for that input.
  final String? inputId;

  final NotificationButtonStyle? buttonStyle;
}

class NotificationMessage {
  /// Build a message using one of the plugin's built-in templates. Supply
  /// [actions] / [inputs] to attach buttons and input fields.
  NotificationMessage.fromPluginTemplate(
    this.id,
    String this.title,
    String this.body, {
    this.image,
    this.largeImage,
    this.launch,
    this.group,
    this.payload = const {},
    this.actions = const [],
    this.inputs = const [],
  }) : templateType = TemplateType.plugin {
    assert(id.trim().isNotEmpty, 'id must not be empty');
    assert(group == null || group!.trim().isNotEmpty,
        'group must not be empty when provided');
  }

  /// Build a message whose content is provided as a full toast XML string
  /// (passed separately to [WindowsNotification.showNotificationCustomTemplate]).
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
        actions = const [],
        inputs = const [] {
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
        group = json['group'] as String?,
        launch = json['launch'] as String?,
        payload = Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
        templateType = TemplateType.values
            .firstWhere((e) => e.name == json['templateType']),
        actions = const [],
        inputs = const [];

  /// Unique identifier within the notification's group.
  final String id;

  final TemplateType templateType;
  final String? title;
  final String? body;
  final String? image;
  final String? largeImage;

  /// Group label, used to remove a batch of notifications at once.
  final String? group;

  /// Launch string delivered to the app when the toast body is tapped.
  final String? launch;

  final Map<String, dynamic> payload;
  final List<NotificationAction> actions;
  final List<NotificationInput> inputs;

  /// Wire-format payload embedded in the toast XML so the original message
  /// can be reconstructed in callback handlers. Internal.
  Map<String, dynamic> toPayloadMap() => {
        'title': title,
        'body': body,
        'tag': id,
        'image': image,
        'largeImage': largeImage,
        'group': group,
        'launch': launch,
        'templateType': templateType.name,
        'payload': payload,
      };

  /// Reconstruct from a callback payload. Internal.
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

  /// What happened to the notification.
  final NotificationEvent event;

  /// The message that was originally sent.
  final NotificationMessage message;

  /// `arguments` attribute from the activated `<action>` or `<toast>`. Null
  /// for dismissal events.
  final String? arguments;

  /// Values from any `<input>` elements on the toast, keyed by input id.
  final Map<String, String> userInput;
}
