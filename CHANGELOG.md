## 1.0.0

First release of `flutter_desktop_notifications`, a fork and rewrite of
`windows_notification` by mrtnetwork. Ships a Windows implementation today;
macOS and Linux are planned.

- Structured `NotificationMessage.fromPluginTemplate` with title, body, a small
  circle-cropped logo, a large image, and a hero image.
- Action buttons and input fields (text or selection) built from Dart, with
  proper XML escaping. No hand-written markup needed for reply boxes or snooze
  lists. Buttons support `success` / `critical` styles and a context-menu
  placement.
- Rich content: scenarios (`reminder`, `alarm`, `incomingCall`, `urgent`),
  short/long duration, attribution lines, extra styled text lines, system or
  looping `NotificationAudio`, an indeterminate or determinate
  `NotificationProgress`, and a `displayTimestamp` override.
- `WidgetToImage.toPng` / `toPngFile` render any Flutter widget off-screen to a
  PNG, for dropping live-generated content into a toast's hero image.
- `NotificationMessage.fromCustomTemplate` for shipping raw toast XML when the
  built-ins do not cover something.
- Activation and dismissal callbacks via `setCallback`, carrying the original
  message, the action arguments, and any typed input.
- Remove delivered toasts by id, by group, or all at once.
- `WindowsNotification.registerAumid` writes the Start Menu shortcut Windows
  needs to attribute toasts to an unpackaged app's name and icon.
- `WindowsNotification.bringAppToForeground` raises and un-minimizes the window,
  for the "Open" action in a callback.
