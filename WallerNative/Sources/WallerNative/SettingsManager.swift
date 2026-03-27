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
        case audioReactive     = "wallr.audioReactive"
        case audioSmoothing    = "wallr.audioSmoothing"
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

    var audioReactive: Bool {
        get { defaults.bool(forKey: Key.audioReactive.rawValue) }
        set { 
            defaults.set(newValue, forKey: Key.audioReactive.rawValue) 
            NotificationCenter.default.post(name: .audioReactiveChanged, object: nil)
        }
    }

    var audioSmoothing: Float {
        get { defaults.object(forKey: Key.audioSmoothing.rawValue) == nil ? 0.7 : defaults.float(forKey: Key.audioSmoothing.rawValue) }
        set { defaults.set(newValue, forKey: Key.audioSmoothing.rawValue) }
    }

    var lastVideoPath: String? {
        get { defaults.string(forKey: Key.lastVideoPath.rawValue) }
        set { defaults.set(newValue, forKey: Key.lastVideoPath.rawValue) }
    }
}

extension Notification.Name {
    static let audioReactiveChanged = Notification.Name("waller.audioReactiveChanged")
}
