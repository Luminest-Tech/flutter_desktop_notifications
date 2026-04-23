## 2.1.0 (unreleased)

### New

- Rich notification content is now first-class on `NotificationMessage.fromPluginTemplate`:
  - `scenario` (`defaultScenario` / `reminder` / `alarm` / `incomingCall` / `urgent`) and `duration` (`short` / `long`).
  - `heroImage` — the big banner image at the top of a toast, separate from the small `image` (appLogoOverride).
  - `attribution` — the dim source/sender line at the bottom of the toast body.
  - `extraTexts: List<NotificationText>` — additional styled body lines with `hint-style`, `hint-align`, `hint-maxLines`.
  - `audio: NotificationAudio` — silent / named system sound / looping via the `NotificationSound` enum (Default, IM, Mail, Reminder, SMS, Alarm, Alarm2–10, Call, Call2–10) or a custom source URI.
  - `progress: NotificationProgress` — title, value (or `null` for indeterminate), `valueStringOverride`, status text.
  - `contextMenu: true` on a `NotificationAction` renders it in the toast's `…` overflow menu instead of as a button.
  - `displayTimestamp` — override the "when" shown in the Action Center.
  - `activationType` — controls the *toast body's* activation (foreground / background / protocol). Defaults to `foreground` (BREAKING relative to 2.0.0's hardcoded `protocol`); opt in to `protocol` when you want Windows to open a URL from `launch`.
- `WidgetToImage.toPng(widget, size)` / `WidgetToImage.toPngFile(widget, size)` render any Flutter widget off-screen to a PNG — useful for dropping live-generated content into `heroImage`. Uses a detached `BuildOwner` / `PipelineOwner` pipeline, no need to mount the widget first.
- `WindowsNotification.bringAppToForeground()` — raises and un-minimizes the current window. Intended for use from a notification callback so your "Open" action button can surface the already-running app.

### Breaking (since 2.0.0 was not published)

- Toast-body default activation changed from `protocol` to `foreground`. Apps that set `launch` to a URL (e.g. `"https://…"`) expecting Windows to open it on body-tap must now also set `activationType: NotificationActivationType.protocol`. The wikipedia example in the example app shows the pattern.

## 2.0.0

Full modernization. Most of the public API was renamed; existing 1.x code will not compile unchanged.

### Breaking changes

- Renamed misspelled public identifiers:
  - `EventType` → `NotificationEvent`, with members `activated`, `dismissedByUser`, `dismissedByApp`, `dismissedByTimeout`.
  - `NotificationCallBackDetails` → `NotificationCallbackDetails`; its `eventType` field is now `event` and `argrument` is now `arguments`.
  - `NotificationMessage.temolateType` → `templateType`; `largImage` → `largeImage`.
  - `WindowsNotification.initNotificationCallBack` → `setCallback`.
  - `OnTapNotification` → `NotificationCallback` (same signature).
- `NotificationCallbackDetails.userInput` is now `Map<String, String>` instead of `Map<String, dynamic>`.
- Removed the hardcoded `#1#` large-image placeholder in favour of a real XML builder; the `showNotification` / `show_notification_image` / `custom_template` method-channel methods were consolidated into a single `show_toast` call and the C++ event-callback method names were renamed to match the new `NotificationEvent` enum. Calling 1.x Dart against 2.x native (or vice versa) will not work — upgrade both together.

### New

- `WindowsNotification.registerAumid` creates (or refreshes) the Start Menu shortcut Windows needs to attribute your toasts to your app's name and icon, instead of borrowing a system AUMID like PowerShell's. Unpackaged Flutter apps can now ship a normal toast experience by calling this once at startup.
- `NotificationAction`, `NotificationInput` (text / selection), and `NotificationSelection` let you attach buttons and input fields to a plugin template without writing XML. The built-in template now composes real toast XML on the Dart side with proper escaping.
- `NotificationButtonStyle` for `success` / `critical` action buttons.
- `NotificationActivationType` enum (`foreground`, `background`, `protocol`) on action buttons.

### Fixed

- The `custom_template` path attached `Activated` / `Dismissed` handlers *after* `Show()`, so fast activations could be missed. Handlers are now attached beforehand, on every path.
- Hardened C++ argument parsing: missing or wrong-typed Dart-side keys no longer throw `std::bad_variant_access` and silently swallow the call.
- `onActivate` no longer crashes when a user-input value isn't `IStringable` — falls back to an empty string.
- The plugin now caches the host HWND eagerly so `setCallback` works even if callers never call `init()` first, and `PostMessage` failures no longer leak the encoded message buffer.
- Removed `std::cerr` debug output and the `print` line in the Dart callback dispatcher.
- `removeNotificationId` and `removeNotificationGroup` now throw `ArgumentError` (not bare `Exception`) on empty input.

### Tooling

- SDK constraints raised to Dart `^3.3.0` / Flutter `>=3.19.0`.
- `flutter_lints` replaces `lints` and three extra rules are enabled.

---

Prior history, for reference:

## 1.3.0
- fix issue [#22](https://github.com/mrtnetwork/flutter_windows_notification/issues/22)

## 1.2.0
- fix issue [#18](https://github.com/mrtnetwork/flutter_windows_notification/issues/18)

## 1.1.0
- fix issue [#9](https://github.com/mrtnetwork/flutter_windows_notification/issues/9)

## 1.0.0
- Fixed some bugs.
- Added properties to read user input.
- Added support for all event types.
- Updated SDK version and dependencies.
