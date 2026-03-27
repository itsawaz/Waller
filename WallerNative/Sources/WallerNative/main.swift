import AppKit

// Entry point — must be a class-based NSApplication for Dock-icon-free operation
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Policy .accessory = no Dock icon, no menu bar app menu — purely tray-driven
app.setActivationPolicy(.accessory)

app.run()
