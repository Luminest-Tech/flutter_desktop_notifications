#ifndef FLUTTER_PLUGIN_WINDOWS_NOTIFICATION_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOWS_NOTIFICATION_PLUGIN_H_

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.UI.Notifications.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/method_call.h>

#include <memory>
#include <optional>
#include <string>

namespace windows_notification {

class WindowsNotificationPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit WindowsNotificationPlugin(flutter::PluginRegistrarWindows* registrar);
  ~WindowsNotificationPlugin() override;

  WindowsNotificationPlugin(const WindowsNotificationPlugin&) = delete;
  WindowsNotificationPlugin& operator=(const WindowsNotificationPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void ShowToast(const flutter::EncodableMap& args);
  void ClearHistory(const flutter::EncodableMap& args);
  void RemoveNotification(const flutter::EncodableMap& args);
  void RemoveGroup(const flutter::EncodableMap& args);
  void RegisterAumid(const flutter::EncodableMap& args);
  void BringToForeground();

  void OnActivate(
      winrt::Windows::UI::Notifications::ToastNotification const& sender,
      winrt::Windows::Foundation::IInspectable const& args);
  void OnDismissed(
      winrt::Windows::UI::Notifications::ToastNotification const& sender,
      winrt::Windows::UI::Notifications::ToastDismissedEventArgs const& args);

  void PostEventToMainThread(std::string method_name,
                             flutter::EncodableValue args);
  void HandleBackgroundMessage(LPARAM lParam);
  std::optional<LRESULT> WProc(HWND hwnd, UINT message, WPARAM wParam,
                               LPARAM lParam);
  void CacheHostWindow();

  winrt::Windows::UI::Notifications::ToastNotificationManager toast_manager_{};

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  const flutter::StandardMethodCodec* codec_;

  HWND host_window_ = nullptr;
  int proc_id_ = -1;

  // Custom WM_USER-range message used to marshal toast events back to the
  // Flutter UI thread. Arbitrary value; only this plugin listens for it.
  static constexpr UINT kNotificationThreadMessageId = 0x8000 + 0x5A5A;
};

}  // namespace windows_notification

#endif  // FLUTTER_PLUGIN_WINDOWS_NOTIFICATION_PLUGIN_H_
