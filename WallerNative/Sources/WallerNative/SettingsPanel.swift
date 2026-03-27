import AppKit
import LaunchAtLogin

// MARK: - Toggle action helper (needed for NSSwitch target/action pattern)
private class SwitchAction: NSObject {
    let onChange: (Bool) -> Void
    init(_ onChange: @escaping (Bool) -> Void) { self.onChange = onChange }
    @objc func toggled(_ sender: NSSwitch) { onChange(sender.state == .on) }
}

// MARK: - Settings Panel

class SettingsPanel: NSPanel {

    private var actions: [SwitchAction] = [] // retain switch actions

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 370),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.title = "Waller Settings"
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.appearance = NSAppearance(named: .darkAqua)
        self.isReleasedWhenClosed = false
        self.center()
        setup()
    }

    private func setup() {
        let s = SettingsManager.shared
        let bg = NSView(frame: contentView!.bounds)
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor(srgbRed: 0.09, green: 0.09, blue: 0.13, alpha: 1).cgColor
        bg.autoresizingMask = [.width, .height]
        contentView!.addSubview(bg)

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 0
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: bg.topAnchor, constant: 56),
            stack.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
        ])

        // ── Playback section ──────────────────────────────────────
        stack.addArrangedSubview(sectionHeader("PLAYBACK"))
        stack.addArrangedSubview(divider())
        stack.addArrangedSubview(row(
            sf: "battery.50", title: "Pause on Battery",
            detail: "Pause wallpaper when running on battery",
            isOn: s.pauseOnBattery,
            onChange: { SettingsManager.shared.pauseOnBattery = $0 }
        ))
        stack.addArrangedSubview(divider())
        stack.addArrangedSubview(row(
            sf: "rectangle.fill.on.rectangle.fill", title: "Pause on Fullscreen",
            detail: "Pause when any app goes fullscreen",
            isOn: s.pauseOnFullscreen,
            onChange: { SettingsManager.shared.pauseOnFullscreen = $0 }
        ))
        stack.addArrangedSubview(divider())
        stack.addArrangedSubview(row(
            sf: "speaker.slash.fill", title: "Mute Audio",
            detail: "Silence wallpaper audio (recommended)",
            isOn: s.isMuted,
            onChange: { SettingsManager.shared.isMuted = $0 }
        ))

        // ── System section ────────────────────────────────────────
        stack.addArrangedSubview(sectionHeader("SYSTEM"))
        stack.addArrangedSubview(divider())
        stack.addArrangedSubview(row(
            sf: "bolt.fill", title: "Launch at Login",
            detail: "Start Waller automatically on login",
            isOn: LaunchAtLogin.isEnabled,
            onChange: { LaunchAtLogin.isEnabled = $0 }
        ))

        // ── Footer ────────────────────────────────────────────────
        let footer = NSTextField(labelWithString: "Waller 1.0.0  ·  Made with ♥ using Swift + AVFoundation")
        footer.font = .systemFont(ofSize: 11)
        footer.textColor = NSColor.tertiaryLabelColor
        footer.alignment = .center
        footer.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(footer)
        NSLayoutConstraint.activate([
            footer.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            footer.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -18),
        ])
    }

    // MARK: - Builder helpers

    private func sectionHeader(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = NSColor.secondaryLabelColor
        let wrap = padded(label, top: 22, left: 24, bottom: 6, right: 24)
        return wrap
    }

    private func divider() -> NSView {
        let line = NSView()
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor.separatorColor.cgColor
        line.translatesAutoresizingMaskIntoConstraints = false
        let wrap = NSView()
        wrap.addSubview(line)
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 60),
            line.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            line.topAnchor.constraint(equalTo: wrap.topAnchor),
            line.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 0.5),
        ])
        return wrap
    }

    private func row(sf: String, title: String, detail: String,
                     isOn: Bool, onChange: @escaping (Bool) -> Void) -> NSView {
        // Icon
        let img = NSImageView()
        img.image = NSImage(systemSymbolName: sf, accessibilityDescription: nil)
        img.contentTintColor = .controlAccentColor
        img.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            img.widthAnchor.constraint(equalToConstant: 20),
            img.heightAnchor.constraint(equalToConstant: 20),
        ])

        // Labels
        let titleLbl = NSTextField(labelWithString: title)
        titleLbl.font = .systemFont(ofSize: 13, weight: .medium)
        titleLbl.textColor = .labelColor

        let detailLbl = NSTextField(labelWithString: detail)
        detailLbl.font = .systemFont(ofSize: 11)
        detailLbl.textColor = .secondaryLabelColor

        let textStack = NSStackView(views: [titleLbl, detailLbl])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 1

        // Switch
        let sw = NSSwitch()
        sw.state = isOn ? .on : .off
        let action = SwitchAction(onChange)
        self.actions.append(action)
        sw.target = action
        sw.action = #selector(SwitchAction.toggled(_:))

        let rowStack = NSStackView(views: [img, textStack, sw])
        rowStack.spacing = 14
        rowStack.alignment = .centerY
        rowStack.distribution = .fill

        let wrap = padded(rowStack, top: 10, left: 20, bottom: 10, right: 20)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return wrap
    }

    private func padded(_ view: NSView, top: CGFloat, left: CGFloat,
                        bottom: CGFloat, right: CGFloat) -> NSView {
        let wrap = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: wrap.topAnchor, constant: top),
            view.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: left),
            view.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -right),
            view.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -bottom),
        ])
        return wrap
    }

    func showPanel() {
        makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
