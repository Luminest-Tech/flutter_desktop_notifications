# flutter_desktop_notifications

Native desktop notifications for Flutter. Build a notification from a structured
template or ship raw markup, attach buttons and reply boxes, get callbacks when
the user clicks or dismisses, and pull notifications back out of the system tray.

Today this ships a **Windows** implementation built on the WinRT toast APIs.
macOS and Linux are planned, so the package is named for where it is going. If
you only need Windows right now, it is ready.

This started as a fork and rewrite of
[`windows_notification`](https://pub.dev/packages/windows_notification) by
mrtnetwork. The public API was reworked, the native side hardened, and a few
features added (rich content, a widget-to-image hero renderer, and a Start Menu
AUMID helper for unpackaged apps).

| | | |
|---|---|---|
| ![Hero image from a Flutter widget](https://raw.githubusercontent.com/Luminest-Tech/flutter_desktop_notifications/main/screenshots/toast-hero.png) | ![Inline reply box](https://raw.githubusercontent.com/Luminest-Tech/flutter_desktop_notifications/main/screenshots/toast-reply.png) | ![Progress bar](https://raw.githubusercontent.com/Luminest-Tech/flutter_desktop_notifications/main/screenshots/toast-progress.png) |

The `example/` app fires every one of these. More shots are in the pub.dev
gallery.

## What you can send

- Built-in templates with a title, body, a small circle-cropped logo, and a
  large hero image.
- Action buttons and input fields (text or selection) without hand-writing XML.
- Scenarios (reminder, alarm, incoming call, urgent), system or looping sounds,
  progress bars, attribution lines, and extra styled text lines.
- Any Flutter widget, rasterized off-screen and used as the hero image.
- Fully custom toast XML when the built-ins do not cover something.
- Activation and dismissal callbacks carrying the original message, the action
  arguments, and any typed input.
- Removal of delivered notifications by id, by group, or all at once.

## Install

```yaml
dependencies:
  flutter_desktop_notifications: ^1.0.0
```

```dart
import 'package:flutter_desktop_notifications/flutter_desktop_notifications.dart';
```

## Registering an Application User Model ID (AUMID)

On Windows, the OS will not show a toast whose AUMID is not registered. The
AUMID is also what it uses to look up the sender's name and icon.

- **Packaged (MSIX) apps**: the manifest supplies the AUMID. Leave
  `applicationId` null.
- **Unpackaged apps**: call the built-in helper once on startup.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowsNotification.registerAumid(
    aumid: 'com.example.myapp',
    displayName: 'My App',
    // iconPath: r'C:\path\to\custom.ico', // optional; defaults to the exe icon
  );
  runApp(const MyApp());
}

final notifier = WindowsNotification(applicationId: 'com.example.myapp');
```

`registerAumid` writes (or refreshes) a Start Menu shortcut at
`%APPDATA%\Microsoft\Windows\Start Menu\Programs\{displayName}.lnk` that points
at the running executable and carries `System.AppUserModel.ID`. The call is
idempotent, so it is safe to run on every launch. Uninstallers should delete
that `.lnk`.

Microsoft recommends AUMIDs shaped like
`CompanyName.ProductName.SubProduct.VersionInformation`. The helper enforces the
hard limits: non-empty, 129 characters or fewer, no whitespace.

A couple of caveats. `registerAumid` sets up enough for Windows to show toasts
under your branding, but action buttons that need to cold-launch a closed app
still require a COM server registered against the AUMID, which is out of scope
here. And if you move or rename the exe, call it again so the shortcut points at
the new location.

## Basic use

```dart
final notifier = WindowsNotification(applicationId: 'com.example.myapp');

await notifier.setCallback((details) {
  switch (details.event) {
    case NotificationEvent.activated:
      // details.arguments: the activated action's `arguments`, or the toast's
      //                    `launch` value for a body tap.
      // details.userInput: { inputId: value } from any input fields.
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

Attach buttons and a reply box straight to a built-in template:

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

In the callback, the typed text is at `details.userInput['reply']`.

Selection inputs work the same way:

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

## Images and links

```dart
NotificationMessage.fromPluginTemplate(
  'open-wiki',
  'Wikipedia',
  'Tap to open the article.',
  image: r'C:\path\to\avatar.png',      // small circle-cropped logo
  largeImage: r'C:\path\to\hero.png',   // big image below the text
  launch: 'https://en.wikipedia.org/',  // opens in the default browser
  activationType: NotificationActivationType.protocol,
);
```

The toast body's own activation defaults to `foreground`. Set it to `protocol`
when `launch` is a URL you want Windows to open on a body tap.

## Hero image from a Flutter widget

`WidgetToImage` renders any widget off-screen to a PNG, so you can put
live-generated content in a notification without mounting the widget first.
Toast hero images are 364 x 180; pass a higher `pixelRatio` for crisp output.

```dart
final path = await WidgetToImage.toPngFile(
  widget: NowPlayingCard(track: track),
  size: const Size(364, 180),
  pixelRatio: 2.0,
);

await notifier.showNotificationPluginTemplate(
  NotificationMessage.fromPluginTemplate(
    'now-playing',
    'Now playing',
    'Neil Young · Harvest Moon',
    heroImage: path,
  ),
);
```

## Custom XML

When the built-ins are not enough, send raw toast XML:

```dart
const template = '''
<toast scenario="reminder" launch="open=event&amp;id=1983">
  <visual>
    <binding template="ToastGeneric">
      <text>Design review</text>
      <text>Room 2001 / Building 135</text>
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

The [toast XML schema reference](https://learn.microsoft.com/windows/apps/design/shell/tiles-and-notifications/toast-xml-schema)
lists every supported element.

## Removing notifications

```dart
await notifier.clearNotificationHistory();              // everything from this app
await notifier.removeNotificationGroup('meetings');     // all in a group
await notifier.removeNotificationId('meeting-1983', 'meetings'); // a single toast
```

## Platform support

| Platform | Status |
|----------|--------|
| Windows  | Supported (WinRT toast notifications) |
| macOS    | Planned |
| Linux    | Planned |

## Example

A full demo lives in `example/`. It has an accent and light/dark switcher and a
button for every kind of notification, including the widget-to-hero-image
renderer.

```bash
cd example
flutter run -d windows
```
