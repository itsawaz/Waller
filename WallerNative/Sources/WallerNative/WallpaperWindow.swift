import AppKit
import AVFoundation
import CoreGraphics
import WebKit

// MARK: - Content type

enum WallpaperContent {
    case video(URL)
    case html(String)
    case none
}

// MARK: - Window

class WallpaperWindow: NSWindow {

    // AVFoundation pipeline
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var loopObserver: NSObjectProtocol?

    // WebKit pipeline
    private var webView: WKWebView?

    // State
    private(set) var currentContent: WallpaperContent = .none
    private var isPausedByMonitor = false

    private static var desktopFrame: NSRect {
        NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1512, height: 982)
    }

    // MARK: - Init

    init() {
        super.init(
            contentRect: WallpaperWindow.desktopFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        let wallpaperLevel = Int(CGWindowLevelForKey(.desktopWindow)) - 1
        self.level = NSWindow.Level(rawValue: wallpaperLevel)

        self.backgroundColor = .black
        self.isOpaque = true
        self.hasShadow = false
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.ignoresMouseEvents = true
        self.isReleasedWhenClosed = false

        let view = NSView(frame: WallpaperWindow.desktopFrame)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        self.contentView = view

        self.orderBack(nil)
    }

    // MARK: - Video Playback

    func playVideo(url: URL) {
        clearAll()
        currentContent = .video(url)

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.isMuted = SettingsManager.shared.isMuted
        isPausedByMonitor = false

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item, queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }

        guard let contentView else { return }
        let layer = AVPlayerLayer(player: player!)
        layer.videoGravity = .resizeAspectFill
        layer.frame = contentView.bounds
        contentView.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        contentView.layer?.addSublayer(layer)
        playerLayer = layer

        player?.play()
        SettingsManager.shared.lastVideoPath = url.path
        print("[WallpaperWindow] Playing video: \(url.lastPathComponent)")
    }

    // MARK: - HTML / WebView Playback

    func playHTML(_ htmlString: String) {
        clearAll()
        currentContent = .html(htmlString)

        guard let contentView else { return }

        let config = WKWebViewConfiguration()
        // macOS 13+: enable JS via WKWebpagePreferences on each navigation
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs

        let wv = WKWebView(frame: contentView.bounds, configuration: config)
        wv.autoresizingMask = [.width, .height]
        wv.wantsLayer = true
        wv.layer?.backgroundColor = NSColor.black.cgColor

        // Disable all user interaction — the window ignores mouse anyway,
        // but this prevents any accidental WebKit highlighting/selection
        wv.allowsMagnification = false
        wv.allowsBackForwardNavigationGestures = false
        wv.setValue(false, forKey: "drawsBackground")

        contentView.addSubview(wv)
        webView = wv

        wv.loadHTMLString(htmlString, baseURL: nil)
        print("[WallpaperWindow] Loaded HTML wallpaper.")
    }

    // MARK: - Monitor-driven Pause / Resume

    func pauseByMonitor() {
        guard !isPausedByMonitor else { return }
        isPausedByMonitor = true
        player?.pause()
        webView?.evaluateJavaScript("document.body.style.animationPlayState='paused'", completionHandler: nil)
        print("[WallpaperWindow] Paused by monitor.")
    }

    func resumeByMonitor() {
        guard isPausedByMonitor else { return }
        isPausedByMonitor = false
        player?.play()
        webView?.evaluateJavaScript("document.body.style.animationPlayState='running'", completionHandler: nil)
        print("[WallpaperWindow] Resumed by monitor.")
    }

    // MARK: - Stop

    func stopPlayback() {
        clearAll()
        currentContent = .none
    }

    private func clearAll() {
        // Stop video
        player?.pause()
        if let obs = loopObserver {
            NotificationCenter.default.removeObserver(obs)
            loopObserver = nil
        }
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil

        // Stop web view
        webView?.loadHTMLString("", baseURL: nil)
        webView?.removeFromSuperview()
        webView = nil

        isPausedByMonitor = false
    }

    var isPlaying: Bool { (player?.rate ?? 0) > 0 || webView != nil }

    // MARK: - Audio

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
        SettingsManager.shared.isMuted = muted
    }

    // MARK: - Lock Screen / Desktop Wallpaper

    func setCurrentFrameAsDesktopWallpaper() {
        // For HTML wallpaper: snapshot the WKWebView
        if case .html = currentContent, let wv = webView {
            wv.takeSnapshot(with: nil) { [weak self] image, error in
                if let error { print("[WallpaperWindow] Snapshot error: \(error)"); return }
                guard let image else { return }
                self?.writeImageAsWallpaper(image)
            }
            return
        }

        // For video: grab current AVPlayer frame
        guard let player,
              let currentItem = player.currentItem else { return }

        let gen = AVAssetImageGenerator(asset: currentItem.asset)
        gen.appliesPreferredTrackTransform = true
        gen.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        gen.requestedTimeToleranceAfter  = CMTime(seconds: 0.5, preferredTimescale: 600)

        gen.generateCGImageAsynchronously(for: player.currentTime()) { cg, _, error in
            if let error { print("[WallpaperWindow] Frame capture error: \(error)"); return }
            guard let cg else { return }
            let image = NSImage(cgImage: cg, size: NSScreen.main?.frame.size ?? .zero)
            DispatchQueue.main.async { self.writeImageAsWallpaper(image) }
        }
    }

    private func writeImageAsWallpaper(_ image: NSImage) {
        let dest = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("waller_wallpaper.jpg")
        if let tiff = image.tiffRepresentation,
           let bmp  = NSBitmapImageRep(data: tiff),
           let jpg  = bmp.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) {
            try? jpg.write(to: dest)
        }
        guard let screen = NSScreen.main else { return }
        do {
            try NSWorkspace.shared.setDesktopImageURL(dest, for: screen, options: [:])
            print("[WallpaperWindow] Desktop wallpaper updated.")
        } catch {
            print("[WallpaperWindow] setDesktopImageURL error: \(error)")
        }
    }
}
