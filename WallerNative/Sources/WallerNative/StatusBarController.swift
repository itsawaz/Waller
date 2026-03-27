import AppKit
import LaunchAtLogin
import UserNotifications

class StatusBarController {
    private let statusItem: NSStatusItem
    private weak var wallpaperWindow: WallpaperWindow?
    private weak var settingsPanel: SettingsPanel?

    private let powerMonitor     = PowerMonitor()
    private let fullscreenMonitor = FullscreenMonitor()
    private let settings = SettingsManager.shared

    // Keep refs for state updates
    private var pauseBatteryItem:    NSMenuItem!
    private var pauseFullscreenItem: NSMenuItem!

    init(wallpaperWindow: WallpaperWindow, settingsPanel: SettingsPanel) {
        self.wallpaperWindow = wallpaperWindow
        self.settingsPanel   = settingsPanel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let btn = statusItem.button {
            // Use SF Symbol for a professional look; fall back to text
            if let icon = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "Waller") {
                var cfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                btn.image = icon.withSymbolConfiguration(cfg)
            } else {
                btn.title = "▶︎"
            }
            btn.toolTip = "Waller – Live Wallpaper Engine"
        }

        buildMenu()
        setupMonitors()

        // Auto-resume last video on launch
        if let path = settings.lastVideoPath,
           FileManager.default.fileExists(atPath: path) {
            wallpaperWindow.playVideo(url: URL(fileURLWithPath: path))
        }
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        // ── Wallpaper ──────────────────────────────────────────
        add(to: menu, "Load Video Wallpaper…",   key: "o", action: #selector(loadVideo))
        add(to: menu, "Stop Wallpaper",           key: "",  action: #selector(stopWallpaper))

        menu.addItem(.separator())

        // ── Interactive ────────────────────────────────────────
        let interactive = NSMenuItem(title: "Interactive Wallpapers", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for w in BuiltinWallpaper.allCases {
            let item = NSMenuItem(title: w.rawValue, action: #selector(loadBuiltin(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = w.html
            sub.addItem(item)
        }
        sub.addItem(.separator())
        let htmlFile = NSMenuItem(title: "Load HTML File…", action: #selector(loadHTMLFile), keyEquivalent: "")
        htmlFile.target = self
        sub.addItem(htmlFile)
        interactive.submenu = sub
        menu.addItem(interactive)

        menu.addItem(.separator())

        // ── Utilities ──────────────────────────────────────────
        add(to: menu, "Set Current Frame as Wallpaper", key: "", action: #selector(captureFrame))

        menu.addItem(.separator())

        // ── Settings ───────────────────────────────────────────
        add(to: menu, "Settings…", key: ",", action: #selector(openSettings))

        menu.addItem(.separator())

        add(to: menu, "Quit Waller", key: "q", action: #selector(quitApp))

        statusItem.menu = menu
    }

    private func add(to menu: NSMenu, _ title: String, key: String, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    // MARK: - Monitors

    private func setupMonitors() {
        powerMonitor.onBatteryStateChanged = { [weak self] onBattery in
            guard let self, self.settings.pauseOnBattery else { return }
            onBattery ? self.wallpaperWindow?.pauseByMonitor() : self.wallpaperWindow?.resumeByMonitor()
        }
        if settings.pauseOnBattery && powerMonitor.isOnBattery {
            wallpaperWindow?.pauseByMonitor()
        }

        fullscreenMonitor.onFullscreenChanged = { [weak self] fs in
            guard let self, self.settings.pauseOnFullscreen else { return }
            fs ? self.wallpaperWindow?.pauseByMonitor() : self.wallpaperWindow?.resumeByMonitor()
        }
        if settings.pauseOnFullscreen { fullscreenMonitor.start() }
    }

    // MARK: - Actions

    @objc private func loadVideo() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.title = "Choose a Video Wallpaper"
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie,
                                     .init(filenameExtension: "mkv")!,
                                     .init(filenameExtension: "webm")!]
        let ok = panel.runModal()
        NSApp.setActivationPolicy(.accessory)
        if ok == .OK, let url = panel.url { wallpaperWindow?.playVideo(url: url) }
    }

    @objc private func loadBuiltin(_ sender: NSMenuItem) {
        guard let html = sender.representedObject as? String else { return }
        wallpaperWindow?.playHTML(html)
    }

    @objc private func loadHTMLFile() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.title = "Choose an HTML Wallpaper"
        panel.allowedContentTypes = [.html]
        let ok = panel.runModal()
        NSApp.setActivationPolicy(.accessory)
        if ok == .OK, let url = panel.url,
           let html = try? String(contentsOf: url, encoding: .utf8) {
            wallpaperWindow?.playHTML(html)
        }
    }

    @objc private func stopWallpaper()  { wallpaperWindow?.stopPlayback() }
    @objc private func openSettings()   { settingsPanel?.showPanel() }
    @objc private func quitApp()        { NSApp.terminate(nil) }

    @objc private func captureFrame() {
        wallpaperWindow?.setCurrentFrameAsDesktopWallpaper()
    }
}
