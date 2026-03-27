import Foundation

/// Persistent user settings backed by UserDefaults.
class SettingsManager {
    static let shared = SettingsManager()
    private let defaults = UserDefaults.standard

    private enum Key: String {
        case pauseOnBattery    = "wallr.pauseOnBattery"
        case pauseOnFullscreen = "wallr.pauseOnFullscreen"
        case isMuted           = "wallr.isMuted"
        case lastVideoPath     = "wallr.lastVideoPath"
    }

    var pauseOnBattery: Bool {
        get { defaults.bool(forKey: Key.pauseOnBattery.rawValue) }
        set { defaults.set(newValue, forKey: Key.pauseOnBattery.rawValue) }
    }

    var pauseOnFullscreen: Bool {
        get { defaults.bool(forKey: Key.pauseOnFullscreen.rawValue) }
        set { defaults.set(newValue, forKey: Key.pauseOnFullscreen.rawValue) }
    }

    var isMuted: Bool {
        get { defaults.object(forKey: Key.isMuted.rawValue) == nil ? true : defaults.bool(forKey: Key.isMuted.rawValue) }
        set { defaults.set(newValue, forKey: Key.isMuted.rawValue) }
    }

    var lastVideoPath: String? {
        get { defaults.string(forKey: Key.lastVideoPath.rawValue) }
        set { defaults.set(newValue, forKey: Key.lastVideoPath.rawValue) }
    }
}
