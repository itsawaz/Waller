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
    private var ambientBloomLayer: AVPlayerLayer?
    private var loopObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?

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

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .audioReactiveChanged, object: nil, queue: .main
        ) { [weak self] _ in
            self?.toggleAudioReactivity()
        }
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

        // 1. Ambient Bloom Layer (Background)
        let bloom = AVPlayerLayer(player: player!)
        bloom.videoGravity = .resizeAspectFill
        bloom.frame = contentView.bounds
        bloom.opacity = 0.0
        
        if let blur = CIFilter(name: "CIGaussianBlur") {
            blur.setDefaults()
            blur.setValue(60.0, forKey: "inputRadius")
            bloom.filters = [blur]
        }
        contentView.layer?.addSublayer(bloom)
        ambientBloomLayer = bloom

        // 2. Main Video Layer (Foreground)
        contentView.layer?.addSublayer(layer)
        playerLayer = layer

        player?.play()
        SettingsManager.shared.lastVideoPath = url.path
        print("[WallpaperWindow] Playing video: \(url.lastPathComponent)")
        
        toggleAudioReactivity()
    }

    // MARK: - Audio Reactivity

    private func toggleAudioReactivity() {
        if SettingsManager.shared.audioReactive && !isPausedByMonitor, case .video = currentContent {
            AudioReactor.shared.onUpdate = { [weak self] level in
                self?.applyVisualizerEffect(level: level)
            }
            AudioReactor.shared.start()
        } else {
            AudioReactor.shared.stop()
            AudioReactor.shared.onUpdate = nil
            // Reset transforms
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.allowsImplicitAnimation = true
                playerLayer?.transform = CATransform3DIdentity
                playerLayer?.opacity = 1.0
                ambientBloomLayer?.transform = CATransform3DIdentity
                ambientBloomLayer?.opacity = 0.0
            }
        }
    }

    private func applyVisualizerEffect(level: CGFloat) {
        guard let layer = playerLayer, let bloom = ambientBloomLayer else { return }

        // Enable incredibly smooth Core Animation transitions
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))

        // Main Scale: 1.0 (quiet) up to 1.06 (loud)
        let scale = 1.0 + (level * 0.06)
        layer.transform = CATransform3DMakeScale(scale, scale, 1.0)
        
        // Bloom Scale: expands slightly more to peek through
        let bloomScale = 1.0 + (level * 0.12)
        bloom.transform = CATransform3DMakeScale(bloomScale, bloomScale, 1.0)
        
        // True-Color Bloom Effect:
        // As bass drops, the main video gets slightly transparent (1.0 -> 0.7)
        // and the heavily blurred bloom layer shoots up in brightness/opacity
        layer.opacity = 1.0 - Float(level * 0.3)
        bloom.opacity = Float(level * 1.5) // Clamps naturally to 1.0 maximum

        CATransaction.commit()
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
        toggleAudioReactivity()
        print("[WallpaperWindow] Paused by monitor.")
    }

    func resumeByMonitor() {
        guard isPausedByMonitor else { return }
        isPausedByMonitor = false
        player?.play()
        webView?.evaluateJavaScript("document.body.style.animationPlayState='running'", completionHandler: nil)
        toggleAudioReactivity()
        print("[WallpaperWindow] Resumed by monitor.")
    }

    // MARK: - Stop

    func stopPlayback() {
        clearAll()
        currentContent = .none
    }

    private func clearAll() {
        toggleAudioReactivity() // Stop audio reactor if running

        // Stop video
        player?.pause()
        if let obs = loopObserver {
            NotificationCenter.default.removeObserver(obs)
            loopObserver = nil
        }
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        ambientBloomLayer?.removeFromSuperlayer()
        ambientBloomLayer = nil
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

}
