import AVFoundation
import Cocoa
import CoreGraphics

/// A borderless window at the macOS desktop window level that plays a looping
/// video behind the desktop icons. One instance is created per display, so the
/// manager owns as many of these as there are `NSScreen`s.
final class WallpaperWindowController {
  private let window: NSWindow
  private let player: AVQueuePlayer
  private var looper: AVPlayerLooper?
  private var isSuspended = false

  /// Layer-backed view hosting the video layer so it resizes with the window.
  private final class PlayerView: NSView {
    init(layer: AVPlayerLayer) {
      super.init(frame: .zero)
      wantsLayer = true
      self.layer = layer
      layer.frame = bounds
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("PlayerView does not support NSCoder.")
    }

    override func layout() {
      super.layout()
      layer?.frame = bounds
    }
  }

  init(screen: NSScreen) {
    let frame = screen.frame

    window = NSWindow(
      contentRect: frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.isReleasedWhenClosed = false

    player = AVQueuePlayer()
    player.isMuted = true

    // kCGDesktopWindowLevel + 1: sits one level above the desktop picture
    // layer, so the video reliably renders on top of the wallpaper on recent
    // macOS versions, while desktop icons (kCGDesktopIconWindowLevel, +20) and
    // all normal windows still stay above it.
    window.level = NSWindow.Level(
      rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1
    )
    window.collectionBehavior = [
      .canJoinAllSpaces,
      .stationary,
      .ignoresCycle,
    ]
    window.ignoresMouseEvents = true
    window.isOpaque = true
    window.hasShadow = false
    window.backgroundColor = .black

    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.videoGravity = .resizeAspectFill
    window.contentView = PlayerView(layer: playerLayer)
  }

  /// Moves the window onto a (possibly new) screen. Called after display
  /// configuration changes.
  func reposition(on screen: NSScreen) {
    window.setFrame(screen.frame, display: true)
  }

  /// Starts a seamless gapless loop of the video at [path]. Any previous
  /// player content is torn down first so no orphaned player is left behind.
  func play(videoAt path: String) {
    looper = nil
    player.removeAllItems()

    let item = AVPlayerItem(url: URL(fileURLWithPath: path))
    looper = AVPlayerLooper(player: player, templateItem: item)

    isSuspended = false
    window.orderFrontRegardless()
    player.play()
  }

  /// Freezes on the current frame without destroying the window.
  func pause() {
    guard !isSuspended else { return }
    isSuspended = true
    player.pause()
  }

  func resume() {
    guard isSuspended else { return }
    isSuspended = false
    player.play()
  }

  /// Stops playback, releases the looper and hides the window. Used when the
  /// live wallpaper is cleared or replaced.
  func clear() {
    looper = nil
    player.removeAllItems()
    window.orderOut(nil)
  }
}
