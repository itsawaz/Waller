import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var wallpaperWindow: WallpaperWindow?
    var statusBarController: StatusBarController?
    var settingsPanel: SettingsPanel?
    var browserPanel: WallpaperBrowserPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        wallpaperWindow  = WallpaperWindow()
        settingsPanel    = SettingsPanel()
        browserPanel     = WallpaperBrowserPanel(wallpaperWindow: wallpaperWindow!)
        statusBarController = StatusBarController(
            wallpaperWindow: wallpaperWindow!,
            settingsPanel: settingsPanel!,
            browserPanel: browserPanel!
        )
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // If the user launches the app again (e.g. from Spotlight or Applications) while it's already running, 
        // we forcefully show the settings panel. This is a critical fallback if their top menu bar is 
        // too crowded (e.g. hidden behind the MacBook Notch).
        settingsPanel?.showPanel()
        return true
    }
}
