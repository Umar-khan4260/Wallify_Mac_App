import Cocoa
import FlutterMacOS

/// Owns the native windowed live-wallpaper player. It keeps one
/// `WallpaperWindowController` per display, exposes the `com.wallify/live_wallpaper`
/// method channel, and handles persistence plus sleep/display changes.
final class LiveWallpaperManager {
  static let shared = LiveWallpaperManager()
  static let channelName = "com.wallify/live_wallpaper"

  private let idKey = "liveWallpaperId"
  private let pathKey = "liveWallpaperPath"

  private var windowControllers: [WallpaperWindowController] = []
  private var currentWallpaperId: String?
  private var currentFilePath: String?

  private var isScreenAsleep = false
  private var observers: [NSObjectProtocol] = []
  private var didStartMonitoring = false

  private init() {}

  // MARK: - Registration

  /// Registers the method channel. Idempotent: safe to call from both
  /// `MainFlutterWindow.awakeFromNib` and the AppDelegate.
  func register(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
    startMonitoringIfNeeded()
  }

  private func startMonitoringIfNeeded() {
    guard !didStartMonitoring else { return }
    didStartMonitoring = true
    startMonitoring()
  }

  // MARK: - Method channel

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setLiveWallpaper":
      guard
        let arguments = call.arguments as? [String: Any],
        let filePath = arguments["filePath"] as? String,
        let wallpaperId = arguments["wallpaperId"] as? String
      else {
        result(FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Expected 'filePath' and 'wallpaperId' arguments.",
          details: nil
        ))
        return
      }
      setLiveWallpaper(filePath: filePath, wallpaperId: wallpaperId, result: result)

    case "clearLiveWallpaper":
      clearLiveWallpaper()
      result(true)

    case "getCurrentLiveWallpaperId":
      result(currentWallpaperId ?? UserDefaults.standard.string(forKey: idKey))

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func setLiveWallpaper(
    filePath: String,
    wallpaperId: String,
    result: @escaping FlutterResult
  ) {
    // AVFoundation on macOS can only decode MP4-family containers, not WebM/GIF.
    let supportedExtensions = ["mp4", "mov", "m4v"]
    let ext = (filePath as NSString).pathExtension.lowercased()
    guard supportedExtensions.contains(ext) else {
      result(FlutterError(
        code: "UNSUPPORTED_FORMAT",
        message: "This video format (.\(ext)) is not supported on macOS.",
        details: nil
      ))
      return
    }

    guard FileManager.default.fileExists(atPath: filePath) else {
      result(FlutterError(
        code: "FILE_NOT_FOUND",
        message: "Video file does not exist: \(filePath)",
        details: nil
      ))
      return
    }

    currentWallpaperId = wallpaperId
    currentFilePath = filePath
    rebuildWindows()
    updateSuspendedState()
    persist(wallpaperId: wallpaperId, filePath: filePath)

    result(true)
  }

  func clearLiveWallpaper() {
    windowControllers.forEach { $0.clear() }
    windowControllers.removeAll()
    currentWallpaperId = nil
    currentFilePath = nil
    UserDefaults.standard.removeObject(forKey: idKey)
    UserDefaults.standard.removeObject(forKey: pathKey)
  }

  // MARK: - Windows

  /// Creates one video window per connected display and starts the current
  /// file in all of them. Existing windows are torn down first.
  private func rebuildWindows() {
    windowControllers.forEach { $0.clear() }
    windowControllers.removeAll()

    guard let filePath = currentFilePath else { return }
    guard !NSScreen.screens.isEmpty else { return }

    for screen in NSScreen.screens {
      let controller = WallpaperWindowController(screen: screen)
      controller.play(videoAt: filePath)
      windowControllers.append(controller)
    }
  }

  // MARK: - Persistence

  private func persist(wallpaperId: String, filePath: String) {
    UserDefaults.standard.set(wallpaperId, forKey: idKey)
    UserDefaults.standard.set(filePath, forKey: pathKey)
  }

  /// Restores the last-applied live wallpaper after a relaunch, as long as the
  /// cached video file still exists.
  func restoreIfNeeded() {
    guard
      let id = UserDefaults.standard.string(forKey: idKey),
      let path = UserDefaults.standard.string(forKey: pathKey),
      FileManager.default.fileExists(atPath: path)
    else {
      return
    }
    currentWallpaperId = id
    currentFilePath = path
    rebuildWindows()
    updateSuspendedState()
  }

  // MARK: - Sleep / display monitoring

  private func startMonitoring() {
    let center = NotificationCenter.default
    let workspace = NSWorkspace.shared.notificationCenter

    observers.append(workspace.addObserver(
      forName: NSWorkspace.screensDidSleepNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isScreenAsleep = true
      self?.updateSuspendedState()
    })

    observers.append(workspace.addObserver(
      forName: NSWorkspace.screensDidWakeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isScreenAsleep = false
      self?.updateSuspendedState()
    })

    observers.append(center.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.screenParametersDidChange()
    })
  }

  private func screenParametersDidChange() {
    // A monitor was connected/disconnected or a resolution changed: rebuild the
    // per-display windows so every screen still shows the live wallpaper.
    rebuildWindows()
    updateSuspendedState()
  }

  /// Pauses playback while the screen is locked/asleep and resumes on wake.
  /// The video intentionally keeps playing on battery power so a freshly set
  /// live wallpaper is never left frozen on a still frame.
  private func updateSuspendedState() {
    let shouldSuspend = isScreenAsleep
    windowControllers.forEach { controller in
      if shouldSuspend {
        controller.pause()
      } else {
        controller.resume()
      }
    }
  }
}
