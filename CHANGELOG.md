## 1.1.2

Metadata only. No code changes.

- Point the repository and README URLs at the renamed GitHub repo,
  `Flutter-Desktop-Notifications`, so pub.dev can verify the repository.

## 1.1.1

Documentation only. No code changes.

- Add status badges (pub, stars, CI, platform, license) and the pub.dev link to
  the README.

## 1.1.0

Cross-platform release. macOS and Linux now have working backends.

- New unified `DesktopNotifier` API that runs on Windows, macOS, and Linux. It
  covers the common subset: title, body, image, action buttons, a reply field
  (Windows and macOS), urgency, and activation/dismissal callbacks. Build
  messages with the existing `NotificationMessage`; each platform renders what
  it supports.
- macOS backend on `UNUserNotificationCenter` (request permission, buttons,
  text reply, image attachments, threads, interruption levels). Delivery
  requires a code-signed app.
- Linux backend on the freedesktop D-Bus spec via `desktop_notifications`. Pure
  Dart, no native code. Buttons and click/close callbacks; urgency hints.
- `DesktopNotifier.cancel(id)` and `cancelAll()` across all platforms. On
  Windows, single-cancel without a group is now best-effort instead of throwing.
- The example app gains a cross-platform row alongside the Windows-only extras.

`WindowsNotification` and its full WinRT feature set are unchanged.

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
