import AppKit
import CoreGraphics

/// Polls the window list every 2 seconds to detect when any app goes fullscreen.
class FullscreenMonitor {
    /// Called with `true` when a fullscreen app is detected, `false` when cleared.
    var onFullscreenChanged: ((Bool) -> Void)?

    private var timer: Timer?
    private var lastState: Bool = false

    func start() {
        guard timer == nil else { return }
        // Check immediately and then every 2 seconds
        check()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.check()
        }
        print("[FullscreenMonitor] Started polling.")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        let fullscreen = hasFullscreenWindow()
        if fullscreen != lastState {
            lastState = fullscreen
            onFullscreenChanged?(fullscreen)
            print("[FullscreenMonitor] Fullscreen state changed: \(fullscreen)")
        }
    }

    private func hasFullscreenWindow() -> Bool {
        guard let screenFrame = NSScreen.main?.frame else { return false }

        // Query only on-screen, non-desktop windows
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
        else { return false }

        for info in windowList {
            // Layer 0 = normal application windows
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let w = bounds["Width"], let h = bounds["Height"]
            else { continue }

            // If a window covers ≥ full screen dimensions it's fullscreen
            if w >= screenFrame.width && h >= screenFrame.height {
                // Make sure it's not our own window
                if let ownerPID = info[kCGWindowOwnerPID as String] as? Int32,
                   ownerPID == ProcessInfo.processInfo.processIdentifier {
                    continue
                }
                return true
            }
        }
        return false
    }
}
