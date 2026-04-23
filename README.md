# windows_notification

Send native Windows toast notifications from Flutter.

Supports:

- Built-in templates with title, body, small image (circle-cropped `appLogoOverride`), and large hero image.
- Fully custom toast XML for anything the built-ins don't cover.
- Structured action buttons and input fields (text or selection). No hand-written XML needed for reply boxes or snooze lists.
- Activation and dismissal callbacks with the original message, action arguments, and user input values.
- Removing notifications from the Action Center by id, by group, or all at once.

Windows-only. Pair with `flutter_local_notifications` if you also need Android or iOS.

## Getting started

```yaml
dependencies:
  windows_notification: ^2.0.0
```

### Registering an Application User Model ID (AUMID)

Windows will not show a toast whose AUMID isn't registered. The AUMID is also what the OS uses to look up the sender's name and icon.

- **Packaged (MSIX) apps**: the manifest supplies the AUMID. Leave `applicationId` null.
- **Unpackaged apps**: use the built-in helper once on startup.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowsNotification.registerAumid(
    aumid: 'com.example.myapp',
    displayName: 'My App',
    // iconPath: 'C:\\path\\to\\custom.ico',  // optional; defaults to the exe's embedded icon
  );
  runApp(const MyApp());
}

final notifier = WindowsNotification(applicationId: 'com.example.myapp');
```

`registerAumid` writes (or refreshes) a Start Menu shortcut at `%APPDATA%\Microsoft\Windows\Start Menu\Programs\{displayName}.lnk` that points at the running executable and has `System.AppUserModel.ID` set to the AUMID. The call is idempotent, so it's safe to run on every launch. Uninstallers should delete that `.lnk` to clean up.

Microsoft recommends AUMIDs in the form `CompanyName.ProductName.SubProduct.VersionInformation`. The helper enforces the hard limits (non-empty, 129 characters or fewer, no whitespace).

Caveats:

- `registerAumid` only sets up enough for Windows to display toasts under your branding. Action-button clicks that need to cold-launch a closed app require a COM server registered against the AUMID, which is out of scope here.
- If you move or rename your exe, call `registerAumid` again so the shortcut points at the new location.

## Basic use

```dart
import 'package:windows_notification/windows_notification.dart';

final notifier = WindowsNotification(applicationId: 'com.example.myapp');

await notifier.setCallback((details) {
  switch (details.event) {
    case NotificationEvent.activated:
      // details.arguments: `arguments` from the activated <action>, or the
      //                    <toast>'s `launch` attribute.
      // details.userInput: { inputId: value } from <input> elements.
      // details.message:   the original NotificationMessage.
      break;
    case NotificationEvent.dismissedByUser:
    case NotificationEvent.dismissedByApp:
    case NotificationEvent.dismissedByTimeout:
      break;
  }
});

await notifier.showNotificationPluginTemplate(
  NotificationMessage.fromPluginTemplate(
    'msg-1',
    'Build complete',
    'flutter build windows finished in 12.4s',
  ),
);
```

## Action buttons and inputs

Attach buttons and input fields directly to a built-in template:

```dart
await notifier.showNotificationPluginTemplate(
  NotificationMessage.fromPluginTemplate(
    'chat:42',
    'New message from Ada',
    'Want to grab lunch?',
    inputs: const [
      NotificationInput.text(id: 'reply', placeholder: 'Quick reply…'),
    ],
    actions: const [
      NotificationAction(
        content: 'Reply',
        arguments: 'action=reply&id=42',
        inputId: 'reply',
      ),
      NotificationAction(
        content: 'Dismiss',
        arguments: 'action=dismiss&id=42',
        buttonStyle: NotificationButtonStyle.critical,
      ),
    ],
  ),
);
```

In your callback, the user's typed text is at `details.userInput['reply']`.

Selection inputs:

```dart
NotificationInput.selection(
  id: 'snooze',
  title: 'Snooze for',
  defaultSelectionId: '15',
  selections: const [
    NotificationSelection(id: '5', content: '5 minutes'),
    NotificationSelection(id: '15', content: '15 minutes'),
    NotificationSelection(id: '60', content: '1 hour'),
  ],
);
```

## Launch strings and images

```dart
NotificationMessage.fromPluginTemplate(
  'open-wiki',
  'Wikipedia',
  'Tap to open the article.',
  image: '/path/to/avatar.png',        // small circle-cropped logo
  largeImage: '/path/to/hero.png',     // big image below the text
  launch: 'https://en.wikipedia.org/', // opens in the default browser (protocol activation)
);
```

For in-app deep links that don't go through a URI scheme, use `fromCustomTemplate` with `<toast activationType="foreground" launch="...">` and read `details.arguments` / `details.message.payload` in your callback.

## Custom XML

When the built-ins aren't enough, ship raw toast XML:

```dart
const template = '''
<toast scenario="reminder" launch="open=event&id=1983">
  <visual>
    <binding template="ToastGeneric">
      <text>Adaptive Tiles Meeting</text>
      <text>Conf Room 2001 / Building 135</text>
      <text>10:00 AM - 10:30 AM</text>
    </binding>
  </visual>
  <actions>
    <input id="snoozeTime" type="selection" defaultInput="15">
      <selection id="1" content="1 minute"/>
      <selection id="15" content="15 minutes"/>
      <selection id="60" content="1 hour"/>
    </input>
    <action activationType="system" arguments="snooze" hint-inputId="snoozeTime" content=""/>
    <action activationType="system" arguments="dismiss" content=""/>
  </actions>
</toast>
''';

await notifier.showNotificationCustomTemplate(
  NotificationMessage.fromCustomTemplate('meeting-1983', group: 'meetings'),
  template,
);
```

See the [toast XML schema reference](https://learn.microsoft.com/windows/apps/design/shell/tiles-and-notifications/toast-xml-schema) for every supported element.

## Removing notifications

```dart
await notifier.clearNotificationHistory();             // everything from this app
await notifier.removeNotificationGroup('meetings');    // all in a group
await notifier.removeNotificationId('meeting-1983', 'meetings'); // a single toast
```

## Migration from 1.x

2.0 is a breaking release. The public API was renamed to fix long-standing typos, and a structured builder for actions/inputs replaces hand-written XML for the common cases.

| 1.x | 2.0 |
| --- | --- |
| `EventType` | `NotificationEvent` |
| `EventType.onActivate` | `NotificationEvent.activated` |
| `EventType.onDismissedUserCanceled` | `NotificationEvent.dismissedByUser` |
| `EventType.onDismissedApplicationHidden` | `NotificationEvent.dismissedByApp` |
| `EventType.onDismissedTimedOut` | `NotificationEvent.dismissedByTimeout` |
| `NotificationCallBackDetails` | `NotificationCallbackDetails` |
| `details.eventType` | `details.event` |
| `details.argrument` | `details.arguments` |
| `NotificationMessage.temolateType` | `NotificationMessage.templateType` |
| `NotificationMessage.largImage` *(field name)* | `NotificationMessage.largeImage` |
| `winNotify.initNotificationCallBack(...)` | `winNotify.setCallback(...)` |
| `OnTapNotification` | `NotificationCallback` |

Callback payload JSON keys changed too (`temolateType` to `templateType`, `largImage` to `largeImage`), so 2.x Dart can't decode callbacks from the 1.x native plugin. Upgrade both sides together.
