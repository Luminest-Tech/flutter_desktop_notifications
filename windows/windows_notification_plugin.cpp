#include "windows_notification_plugin.h"

#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace windows_notification {

using winrt::Windows::Data::Xml::Dom::XmlDocument;
using winrt::Windows::Foundation::IInspectable;
using winrt::Windows::Foundation::IStringable;
using winrt::Windows::UI::Notifications::ToastActivatedEventArgs;
using winrt::Windows::UI::Notifications::ToastDismissalReason;
using winrt::Windows::UI::Notifications::ToastDismissedEventArgs;
using winrt::Windows::UI::Notifications::ToastNotification;
using winrt::Windows::UI::Notifications::ToastNotifier;

using flutter::EncodableMap;
using flutter::EncodableValue;

namespace {

// Fetch a required string from `args`, or return `fallback` if the key is
// missing / not a string. Prevents std::bad_variant_access on unexpected
// Dart-side shapes.
std::string GetString(const EncodableMap& args, const char* key,
                      std::string fallback = "") {
  auto it = args.find(EncodableValue(key));
  if (it == args.end()) return fallback;
  if (const auto* s = std::get_if<std::string>(&it->second)) return *s;
  return fallback;
}

std::optional<std::string> GetOptionalString(const EncodableMap& args,
                                             const char* key) {
  auto it = args.find(EncodableValue(key));
  if (it == args.end()) return std::nullopt;
  if (const auto* s = std::get_if<std::string>(&it->second)) return *s;
  return std::nullopt;
}

}  // namespace

// static
void WindowsNotificationPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "windows_notification",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WindowsNotificationPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WindowsNotificationPlugin::WindowsNotificationPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "windows_notification",
      &flutter::StandardMethodCodec::GetInstance());
  codec_ = &flutter::StandardMethodCodec::GetInstance();

  proc_id_ = registrar->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
        return WProc(hwnd, message, wParam, lParam);
      });

  CacheHostWindow();
}

WindowsNotificationPlugin::~WindowsNotificationPlugin() {
  if (proc_id_ != -1 && registrar_) {
    registrar_->UnregisterTopLevelWindowProcDelegate(proc_id_);
  }
}

void WindowsNotificationPlugin::CacheHostWindow() {
  auto* view = registrar_->GetView();
  if (view == nullptr) return;
  HWND native = view->GetNativeWindow();
  if (native == nullptr) return;
  host_window_ = ::GetAncestor(native, GA_ROOT);
}

void WindowsNotificationPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const std::string& name = method_call.method_name();
  const auto* arg_map = std::get_if<EncodableMap>(method_call.arguments());
  static const EncodableMap kEmpty;
  const EncodableMap& args = arg_map ? *arg_map : kEmpty;

  try {
    if (name == "init") {
      CacheHostWindow();
      result->Success();
    } else if (name == "show_toast") {
      ShowToast(args);
      result->Success();
    } else if (name == "clear_history") {
      ClearHistory(args);
      result->Success();
    } else if (name == "remove_notification") {
      RemoveNotification(args);
      result->Success();
    } else if (name == "remove_group") {
      RemoveGroup(args);
      result->Success();
    } else {
      result->NotImplemented();
    }
  } catch (const winrt::hresult_error& e) {
    result->Error("winrt_error", winrt::to_string(e.message()));
  } catch (const std::exception& e) {
    result->Error("exception", e.what());
  }
}

void WindowsNotificationPlugin::ShowToast(const EncodableMap& args) {
  const std::string tag = GetString(args, "tag");
  const std::string payload = GetString(args, "payload");
  const std::string xml = GetString(args, "template");

  XmlDocument doc;
  doc.LoadXml(winrt::to_hstring(xml));
  doc.DocumentElement().SetAttribute(L"payload", winrt::to_hstring(payload));

  if (auto launch = GetOptionalString(args, "launch")) {
    doc.DocumentElement().SetAttribute(L"launch", winrt::to_hstring(*launch));
  }

  ToastNotification notif{doc};
  if (!tag.empty()) {
    notif.Tag(winrt::to_hstring(tag));
  }
  if (auto group = GetOptionalString(args, "group")) {
    notif.Group(winrt::to_hstring(*group));
  }

  // Event handlers MUST be attached before Show(); otherwise fast
  // activations/dismissals can fire before we wire up.
  notif.Activated({this, &WindowsNotificationPlugin::OnActivate});
  notif.Dismissed({this, &WindowsNotificationPlugin::OnDismissed});

  if (auto app_id = GetOptionalString(args, "application_id")) {
    toast_manager_.CreateToastNotifier(winrt::to_hstring(*app_id)).Show(notif);
  } else {
    toast_manager_.CreateToastNotifier().Show(notif);
  }
}

void WindowsNotificationPlugin::ClearHistory(const EncodableMap& args) {
  if (auto app_id = GetOptionalString(args, "application_id")) {
    toast_manager_.History().Clear(winrt::to_hstring(*app_id));
  } else {
    toast_manager_.History().Clear();
  }
}

void WindowsNotificationPlugin::RemoveNotification(const EncodableMap& args) {
  const std::string tag = GetString(args, "tag");
  const std::string group = GetString(args, "group");
  if (auto app_id = GetOptionalString(args, "application_id")) {
    toast_manager_.History().Remove(winrt::to_hstring(tag),
                                    winrt::to_hstring(group),
                                    winrt::to_hstring(*app_id));
  } else {
    toast_manager_.History().Remove(winrt::to_hstring(tag),
                                    winrt::to_hstring(group));
  }
}

void WindowsNotificationPlugin::RemoveGroup(const EncodableMap& args) {
  const std::string group = GetString(args, "group");
  if (auto app_id = GetOptionalString(args, "application_id")) {
    toast_manager_.History().RemoveGroup(winrt::to_hstring(group),
                                         winrt::to_hstring(*app_id));
  } else {
    toast_manager_.History().RemoveGroup(winrt::to_hstring(group));
  }
}

void WindowsNotificationPlugin::OnActivate(ToastNotification const& sender,
                                           IInspectable const& args) {
  XmlDocument const doc = sender.Content();
  winrt::hstring payload = doc.DocumentElement().GetAttribute(L"payload");

  std::string arguments_str;
  EncodableMap user_input_map;
  if (auto activated = args.try_as<ToastActivatedEventArgs>()) {
    arguments_str = winrt::to_string(activated.Arguments());
    auto user_input = activated.UserInput();
    if (user_input) {
      for (auto const& pair : user_input.GetView()) {
        auto key = winrt::to_string(pair.Key());
        std::string value;
        if (auto stringable = pair.Value().try_as<IStringable>()) {
          value = winrt::to_string(stringable.ToString());
        }
        user_input_map[EncodableValue(std::move(key))] =
            EncodableValue(std::move(value));
      }
    }
  }

  EncodableMap out;
  out[EncodableValue("payload")] = EncodableValue(winrt::to_string(payload));
  out[EncodableValue("arguments")] = EncodableValue(std::move(arguments_str));
  out[EncodableValue("user_input")] = EncodableValue(std::move(user_input_map));
  PostEventToMainThread("activated", EncodableValue(std::move(out)));
}

void WindowsNotificationPlugin::OnDismissed(
    ToastNotification const& sender,
    ToastDismissedEventArgs const& args) {
  XmlDocument const doc = sender.Content();
  winrt::hstring payload = doc.DocumentElement().GetAttribute(L"payload");

  std::string method_name;
  switch (args.Reason()) {
    case ToastDismissalReason::ApplicationHidden:
      method_name = "dismissedByApp";
      break;
    case ToastDismissalReason::UserCanceled:
      method_name = "dismissedByUser";
      break;
    case ToastDismissalReason::TimedOut:
    default:
      method_name = "dismissedByTimeout";
      break;
  }

  EncodableMap out;
  out[EncodableValue("payload")] = EncodableValue(winrt::to_string(payload));
  PostEventToMainThread(std::move(method_name), EncodableValue(std::move(out)));
}

std::optional<LRESULT> WindowsNotificationPlugin::WProc(HWND hwnd, UINT message,
                                                        WPARAM wParam,
                                                        LPARAM lParam) {
  if (message == kNotificationThreadMessageId) {
    HandleBackgroundMessage(lParam);
  }
  return std::nullopt;
}

void WindowsNotificationPlugin::PostEventToMainThread(
    std::string method_name, EncodableValue args) {
  if (host_window_ == nullptr) {
    CacheHostWindow();
    if (host_window_ == nullptr) return;  // nowhere to post; drop the event
  }
  const flutter::MethodCall<EncodableValue> call(
      std::move(method_name), std::make_unique<EncodableValue>(std::move(args)));
  auto encoded = codec_->EncodeMethodCall(call);
  // Ownership of the buffer is transferred to the Windows message queue; the
  // handler on the main thread re-wraps it in a unique_ptr to free it.
  auto* raw = encoded.release();
  if (!::PostMessage(host_window_, kNotificationThreadMessageId, 0,
                     reinterpret_cast<LPARAM>(raw))) {
    delete raw;
  }
}

void WindowsNotificationPlugin::HandleBackgroundMessage(LPARAM lParam) {
  auto* raw = reinterpret_cast<std::vector<uint8_t>*>(lParam);
  if (raw == nullptr) return;
  std::unique_ptr<std::vector<uint8_t>> buffer(raw);
  auto decoded = codec_->DecodeMethodCall(buffer->data(), buffer->size());
  if (!decoded) return;
  channel_->InvokeMethod(
      decoded->method_name(),
      std::make_unique<EncodableValue>(*decoded->arguments()));
}

}  // namespace windows_notification
