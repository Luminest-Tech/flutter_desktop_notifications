#include "windows_notification_plugin.h"

#include <propkey.h>
#include <propvarutil.h>
#include <shlobj.h>
#include <shobjidl.h>

#include <memory>
#include <stdexcept>
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

// Safe string fetch: returns `fallback` if the key is missing or the value
// isn't a string. Without this, std::get<std::string> throws on malformed
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

// Replace reserved Windows filename chars with '_'.
std::wstring SanitizeShortcutName(std::wstring s) {
  for (auto& c : s) {
    switch (c) {
      case L'\\':
      case L'/':
      case L':':
      case L'*':
      case L'?':
      case L'"':
      case L'<':
      case L'>':
      case L'|':
        c = L'_';
        break;
      default:
        break;
    }
  }
  return s;
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
    } else if (name == "register_aumid") {
      RegisterAumid(args);
      result->Success();
    } else if (name == "bring_to_front") {
      BringToForeground();
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

  // Handlers must be attached before Show() or fast user interaction can
  // fire before we wire up.
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

void WindowsNotificationPlugin::RegisterAumid(const EncodableMap& args) {
  const std::string aumid_utf8 = GetString(args, "aumid");
  const std::string display_name_utf8 = GetString(args, "display_name");
  const auto icon_path_utf8 = GetOptionalString(args, "icon_path");

  if (aumid_utf8.empty() || display_name_utf8.empty()) {
    throw std::invalid_argument("aumid and display_name are required");
  }

  const winrt::hstring aumid = winrt::to_hstring(aumid_utf8);
  const winrt::hstring display_name = winrt::to_hstring(display_name_utf8);

  wchar_t exe_path[MAX_PATH];
  if (::GetModuleFileNameW(nullptr, exe_path, MAX_PATH) == 0) {
    winrt::throw_last_error();
  }

  PWSTR programs_folder = nullptr;
  winrt::check_hresult(::SHGetKnownFolderPath(FOLDERID_Programs, 0, nullptr,
                                              &programs_folder));
  std::wstring shortcut_path(programs_folder);
  ::CoTaskMemFree(programs_folder);

  shortcut_path += L"\\";
  shortcut_path += SanitizeShortcutName(std::wstring(display_name));
  shortcut_path += L".lnk";

  winrt::com_ptr<IShellLinkW> shell_link;
  winrt::check_hresult(::CoCreateInstance(CLSID_ShellLink, nullptr,
                                          CLSCTX_INPROC_SERVER,
                                          IID_PPV_ARGS(shell_link.put())));

  winrt::check_hresult(shell_link->SetPath(exe_path));

  if (icon_path_utf8) {
    const winrt::hstring icon_path = winrt::to_hstring(*icon_path_utf8);
    winrt::check_hresult(shell_link->SetIconLocation(icon_path.c_str(), 0));
  } else {
    winrt::check_hresult(shell_link->SetIconLocation(exe_path, 0));
  }

  winrt::com_ptr<IPropertyStore> prop_store;
  winrt::check_hresult(
      shell_link->QueryInterface(IID_PPV_ARGS(prop_store.put())));

  PROPVARIANT aumid_var{};
  winrt::check_hresult(::InitPropVariantFromString(aumid.c_str(), &aumid_var));
  const HRESULT set_hr = prop_store->SetValue(PKEY_AppUserModel_ID, aumid_var);
  ::PropVariantClear(&aumid_var);
  winrt::check_hresult(set_hr);
  winrt::check_hresult(prop_store->Commit());

  winrt::com_ptr<IPersistFile> persist_file;
  winrt::check_hresult(
      shell_link->QueryInterface(IID_PPV_ARGS(persist_file.put())));
  winrt::check_hresult(persist_file->Save(shortcut_path.c_str(), TRUE));
}

void WindowsNotificationPlugin::BringToForeground() {
  if (host_window_ == nullptr) {
    CacheHostWindow();
    if (host_window_ == nullptr) return;
  }
  if (::IsIconic(host_window_)) {
    ::ShowWindow(host_window_, SW_RESTORE);
  } else {
    ::ShowWindow(host_window_, SW_SHOW);
  }
  // Best-effort; Windows may refuse foreground switches when the calling
  // process doesn't own focus. ShowWindow above at least un-minimizes.
  ::SetForegroundWindow(host_window_);
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
    if (host_window_ == nullptr) return;
  }
  const flutter::MethodCall<EncodableValue> call(
      std::move(method_name), std::make_unique<EncodableValue>(std::move(args)));
  auto encoded = codec_->EncodeMethodCall(call);
  // Buffer ownership passes to the Windows message queue; the handler on
  // the UI thread re-wraps in unique_ptr to free.
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
