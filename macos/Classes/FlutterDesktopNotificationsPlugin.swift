import Cocoa
import FlutterMacOS
import UserNotifications

public class FlutterDesktopNotificationsPlugin: NSObject, FlutterPlugin,
  UNUserNotificationCenterDelegate
{
  private let channel: FlutterMethodChannel
  // categoryId -> category, accumulated so concurrent notifications keep their
  // own action sets (setNotificationCategories replaces the whole set).
  private var categories: [String: UNNotificationCategory] = [:]

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    UNUserNotificationCenter.current().delegate = self
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_desktop_notifications/macos",
      binaryMessenger: registrar.messenger)
    let instance = FlutterDesktopNotificationsPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      requestPermission(result: result)
    case "show":
      show(args: call.arguments as? [String: Any] ?? [:], result: result)
    case "cancel":
      let id = (call.arguments as? [String: Any])?["id"] as? String ?? ""
      let center = UNUserNotificationCenter.current()
      center.removeDeliveredNotifications(withIdentifiers: [id])
      center.removePendingNotificationRequests(withIdentifiers: [id])
      result(nil)
    case "cancelAll":
      let center = UNUserNotificationCenter.current()
      center.removeAllDeliveredNotifications()
      center.removeAllPendingNotificationRequests()
      categories.removeAll()
      center.setNotificationCategories([])
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { granted, _ in
      DispatchQueue.main.async { result(granted) }
    }
  }

  private func show(args: [String: Any], result: @escaping FlutterResult) {
    let id = args["id"] as? String ?? UUID().uuidString
    let content = UNMutableNotificationContent()
    content.title = args["title"] as? String ?? ""
    if let subtitle = args["subtitle"] as? String { content.subtitle = subtitle }
    content.body = args["body"] as? String ?? ""
    if (args["sound"] as? String) != "none" { content.sound = .default }
    if let threadId = args["threadId"] as? String { content.threadIdentifier = threadId }

    if #available(macOS 12.0, *) {
      switch args["interruptionLevel"] as? String {
      case "timeSensitive": content.interruptionLevel = .timeSensitive
      case "passive": content.interruptionLevel = .passive
      case "critical": content.interruptionLevel = .critical
      default: content.interruptionLevel = .active
      }
    }

    if let imagePath = args["image"] as? String, !imagePath.isEmpty {
      let url = URL(fileURLWithPath: imagePath)
      if let attachment = try? UNNotificationAttachment(
        identifier: "image-\(id)", url: url, options: nil)
      {
        content.attachments = [attachment]
      }
    }

    let rawActions = args["actions"] as? [[String: Any]] ?? []
    if !rawActions.isEmpty {
      let categoryId = "cat-\(id)"
      let notificationActions: [UNNotificationAction] = rawActions.map { a in
        let actionId = a["id"] as? String ?? ""
        let title = a["title"] as? String ?? ""
        if (a["textInput"] as? Bool) == true {
          return UNTextInputNotificationAction(
            identifier: actionId,
            title: title,
            options: [],
            textInputButtonTitle: title,
            textInputPlaceholder: a["placeholder"] as? String ?? "")
        }
        return UNNotificationAction(
          identifier: actionId, title: title, options: [.foreground])
      }
      let category = UNNotificationCategory(
        identifier: categoryId,
        actions: notificationActions,
        intentIdentifiers: [],
        options: [])
      categories[categoryId] = category
      UNUserNotificationCenter.current().setNotificationCategories(
        Set(categories.values))
      content.categoryIdentifier = categoryId
    }

    let request = UNNotificationRequest(
      identifier: id, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if let error = error {
          result(
            FlutterError(
              code: "show_failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }

  // Show notifications even while the app is in the foreground.
  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(macOS 11.0, *) {
      completionHandler([.banner, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  // Forward taps, button presses, replies, and dismissals to Dart.
  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let id = response.notification.request.identifier
    var payload: [String: Any] = ["id": id]

    switch response.actionIdentifier {
    case UNNotificationDismissActionIdentifier:
      payload["event"] = "dismissed"
    case UNNotificationDefaultActionIdentifier:
      payload["event"] = "activated"
      payload["actionId"] = "default"
    default:
      payload["event"] = "activated"
      payload["actionId"] = response.actionIdentifier
    }

    if let textResponse = response as? UNTextInputNotificationResponse {
      payload["reply"] = textResponse.userText
    }

    channel.invokeMethod("onEvent", arguments: payload)
    completionHandler()
  }
}
