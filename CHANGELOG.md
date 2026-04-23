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
