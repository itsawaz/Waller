import Foundation
import IOKit.ps

/// Monitors the system power source and calls back when the state changes.
class PowerMonitor {
    /// Called whenever battery/AC state changes. `true` = on battery, `false` = on AC power.
    var onBatteryStateChanged: ((Bool) -> Void)?

    private var runLoopSource: CFRunLoopSource?

    init() {
        // We need a raw pointer back to self for the C callback
        let context = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())

        runLoopSource = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(ctx).takeUnretainedValue()
            monitor.onBatteryStateChanged?(monitor.isOnBattery)
        }, context)?.takeRetainedValue()

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }

        print("[PowerMonitor] Started. Currently on battery: \(isOnBattery)")
    }

    /// Returns `true` if the machine is currently running on its internal battery (not plugged in).
    var isOnBattery: Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return false }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any],
                  let type = desc[kIOPSTypeKey] as? String,
                  type == kIOPSInternalBatteryType,
                  let state = desc[kIOPSPowerSourceStateKey] as? String
            else { continue }

            return state == kIOPSBatteryPowerValue
        }
        return false
    }

    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }
}
