import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  /// Must match `kWallpaperMethodChannel` in
  /// lib/lib/data/wallpaper_service.dart.
  private let wallpaperChannelName = "com.myapp/wallpaper"

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: wallpaperChannelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }

    // Windowed video-behind-desktop live wallpapers. Registration is idempotent
    // (MainFlutterWindow also registers the channel during awakeFromNib).
    LiveWallpaperManager.shared.register(binaryMessenger: controller.engine.binaryMessenger)
    LiveWallpaperManager.shared.restoreIfNeeded()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep running after the window closes so the live wallpaper keeps playing.
    return false
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag {
      mainFlutterWindow?.makeKeyAndOrderFront(nil)
      if #available(macOS 14.0, *) {
        NSApp.activate()
      } else {
        NSApp.activate(ignoringOtherApps: true)
      }
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // MARK: - Method channel

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setWallpaper":
      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["filePath"] as? String,
        !path.isEmpty
      else {
        result(FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Expected a non-empty 'filePath' argument.",
          details: nil
        ))
        return
      }
      applyWallpaper(path: path, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Sets the wallpaper on every connected display. Called on the main thread.
  private func applyWallpaper(path: String, result: @escaping FlutterResult) {
    let fileURL = URL(fileURLWithPath: path)

    guard FileManager.default.fileExists(atPath: path) else {
      result(FlutterError(
        code: "FILE_NOT_FOUND",
        message: "Wallpaper file does not exist: \(path)",
        details: nil
      ))
      return
    }

    let screens = NSScreen.screens
    guard !screens.isEmpty else {
      result(FlutterError(
        code: "NO_DISPLAYS",
        message: "No displays are currently connected.",
        details: nil
      ))
      return
    }

    var failures: [String] = []
    var appliedAny = false

    for screen in screens {
      do {
        try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: [:])
        appliedAny = true
      } catch {
        failures.append("\(screen.localizedName): \(error.localizedDescription)")
      }
    }

    // If at least one display was updated, treat the request as successful.
    if appliedAny {
      result(true)
    } else {
      result(FlutterError(
        code: "SET_WALLPAPER_FAILED",
        message: failures.joined(separator: "\n"),
        details: nil
      ))
    }
  }
}
