import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var wallpaperWindow: WallpaperWindow?
    var statusBarController: StatusBarController?
    var settingsPanel: SettingsPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        wallpaperWindow  = WallpaperWindow()
        settingsPanel    = SettingsPanel()
        statusBarController = StatusBarController(
            wallpaperWindow: wallpaperWindow!,
            settingsPanel: settingsPanel!
        )
    }
}
