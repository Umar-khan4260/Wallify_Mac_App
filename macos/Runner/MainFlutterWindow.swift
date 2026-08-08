import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let wallpaperChannel = FlutterMethodChannel(name: "com.myapp/wallpaper",
                                              binaryMessenger: flutterViewController.engine.binaryMessenger)
    
    wallpaperChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "setWallpaper" {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "File path is required", details: nil))
          return
        }
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath) {
          result(FlutterError(code: "FILE_NOT_FOUND", message: "Wallpaper file does not exist at path: \(filePath)", details: nil))
          return
        }
        
        let fileUrl = URL(fileURLWithPath: filePath)
        let workspace = NSWorkspace.shared
        
        do {
          for screen in NSScreen.screens {
            try workspace.setDesktopImageURL(fileUrl, for: screen, options: [:])
          }
          result(true)
        } catch {
          result(FlutterError(code: "SET_WALLPAPER_FAILED", message: "Failed to set wallpaper: \(error.localizedDescription)", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Windowed video-behind-desktop live wallpapers. Registered here (where the
    // engine is guaranteed to exist) as well as from the AppDelegate.
    LiveWallpaperManager.shared.register(binaryMessenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
