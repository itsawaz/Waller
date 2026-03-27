# Waller — Live Wallpaper Engine for macOS

![Waller Icon](AppIcon.png)

> A lightweight, native Swift live wallpaper engine for macOS. Runs silently in your menu bar. No Dock icon. No bloat.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎬 **Video Wallpapers** | Play any MP4, MOV, MKV video looped behind your desktop icons |
| 🌌 **Interactive Wallpapers** | Built-in particle effects: Particle Network, Matrix Rain, Aurora Borealis, Galaxy Field |
| 📄 **HTML Wallpapers** | Load any custom HTML/JS/Canvas file as a live wallpaper |
| 🔋 **Pause on Battery** | Auto-pauses when you unplug, resumes when plugged in |
| 📺 **Pause on Fullscreen** | Stops wallpaper when any app goes fullscreen |
| 🚀 **Launch at Login** | Starts silently when you log in |
| 🖼 **Capture Frame** | Save any video frame as your macOS desktop wallpaper |
| 🔇 **Mute Audio** | Wallpaper audio on/off (muted by default) |

---

## 📸 Screenshot

![Settings Panel](screenshot.png)

---

## 🛠 Requirements

- macOS 13 Ventura or later
- Xcode Command Line Tools (`xcode-select --install`)
- Swift 5.9+

---

## 🚀 Quick Start

### Option A — Download & Run (Recommended)

1. Download **Waller.app** from [Releases](../../releases/latest)
2. Drag to `/Applications`
3. Double-click — look for the **▶︎** icon in your menu bar

### Option B — Build from Source

```bash
git clone https://github.com/neerajsingh0101/Waller.git
cd Waller/WallerNative

# Install dependencies and build .app
swift package resolve
bash build-app.sh

# Run immediately
open Waller.app
```

---

## 🎬 Usage

1. Click the **▶︎** icon in your **menu bar** (top-right)
2. Choose **Load Video Wallpaper…** to pick any `.mp4 / .mov / .mkv` file
3. Or open **Interactive Wallpapers** to pick a built-in particle effect
4. Open **Settings** to configure battery/fullscreen pausing and launch at login

### Controls

| Menu Item | Action |
|---|---|
| Load Video Wallpaper… | Pick a local video file |
| Interactive Wallpapers | Choose a built-in JS particle effect |
| Stop Wallpaper | Clear the active wallpaper |
| Set Current Frame as Wallpaper | Snapshot current frame → desktop wallpaper |
| Settings… | Preferences panel (`⌘,`) |
| Quit Waller | Exit the app |

---

## 🏗 Architecture

```
WallerNative/
├── Sources/WallerNative/
│   ├── main.swift                 App entry — NSApplication + .accessory policy
│   ├── AppDelegate.swift          Lifecycle
│   ├── WallpaperWindow.swift      NSWindow at kCGDesktopWindowLevel, AVPlayerLayer + WKWebView
│   ├── StatusBarController.swift  Menu bar NSStatusItem
│   ├── SettingsPanel.swift        Native dark preferences panel
│   ├── BuiltinWallpapers.swift    4 self-contained HTML/JS particle effects
│   ├── PowerMonitor.swift         IOKit battery state monitoring
│   ├── FullscreenMonitor.swift    CGWindowList fullscreen detection
│   └── SettingsManager.swift      UserDefaults persistence
├── Info.plist                     LSUIElement=YES (no Dock icon)
├── AppIcon.png                    1024×1024 app icon source
└── build-app.sh                   One-command .app bundle builder
```

---

## 📦 Dependencies

- [**LaunchAtLogin-Modern**](https://github.com/sindresorhus/LaunchAtLogin-Modern) by @sindresorhus — MIT License

---

## 📝 License

MIT License © 2026 Neeraj Singh

---

## 🤝 Contributing

PRs welcome! Ideas for future features:
- Multi-monitor support (different wallpaper per screen)
- AI-generated wallpapers (Stable Diffusion integration)
- Playlist / schedule rotation
- Screensaver integration
