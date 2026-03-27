import AppKit

class AboutPanel: NSPanel, NSWindowDelegate {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 380),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.title = "About Waller"
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.appearance = NSAppearance(named: .darkAqua)
        self.isReleasedWhenClosed = false
        self.center()
        self.delegate = self
        
        let bg = NSVisualEffectView(frame: contentView!.bounds)
        bg.material = .sidebar
        bg.blendingMode = .behindWindow
        bg.state = .active
        bg.autoresizingMask = [.width, .height]
        contentView!.addSubview(bg)
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: bg.centerYAnchor, constant: -10)
        ])
        
        // ── Logo ──────────────────────────────────────────────────
        let imgView = NSImageView()
        if let img = NSImage(named: "AppIcon") {
            img.size = NSSize(width: 80, height: 80)
            imgView.image = img
        } else {
            // Fallback to SF symbol if AppIcon isn't loaded
            let fallback = NSImage(systemSymbolName: "play.tv.fill", accessibilityDescription: nil)
            imgView.image = fallback
            imgView.contentTintColor = NSColor(srgbRed: 0.5, green: 0.4, blue: 1.0, alpha: 1)
        }
        imgView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imgView.widthAnchor.constraint(equalToConstant: 80),
            imgView.heightAnchor.constraint(equalToConstant: 80)
        ])
        stack.addArrangedSubview(imgView)
        
        // ── Title & Version ─────────────────────────────────────
        let titleStack = NSStackView()
        titleStack.orientation = .vertical
        titleStack.alignment = .centerX
        titleStack.spacing = 2
        
        let title = NSTextField(labelWithString: "Waller")
        title.font = .systemFont(ofSize: 32, weight: .bold)
        title.textColor = .labelColor
        
        let version = NSTextField(labelWithString: "Version 1.0.0 (Native)")
        version.font = .systemFont(ofSize: 13, weight: .medium)
        version.textColor = .secondaryLabelColor
        
        titleStack.addArrangedSubview(title)
        titleStack.addArrangedSubview(version)
        stack.addArrangedSubview(titleStack)
        stack.setCustomSpacing(25, after: titleStack)
        
        // ── Description ──────────────────────────────────────────
        let desc = NSTextField(labelWithString: "A beautiful, native Live Wallpaper engine for macOS built with Swift and AVFoundation. Experience seamless desktop integration, automatic power conservation, dynamic audio reactivity, and native downloading from your favorite wallpaper galleries.")
        desc.font = .systemFont(ofSize: 13)
        desc.textColor = .labelColor
        desc.alignment = .center
        desc.preferredMaxLayoutWidth = 360
        desc.lineBreakMode = .byWordWrapping
        stack.addArrangedSubview(desc)
        
        stack.setCustomSpacing(25, after: desc)
        
        // ── Credits & GitHub ─────────────────────────────────────
        let creds = NSTextField(labelWithString: "Crafted exclusively for Neeraj Singh")
        creds.font = .systemFont(ofSize: 12, weight: .medium)
        creds.textColor = NSColor(srgbRed: 0.8, green: 0.6, blue: 0.9, alpha: 1.0)
        stack.addArrangedSubview(creds)
    }
    
    func showPanel() {
        makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
