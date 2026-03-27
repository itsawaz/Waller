# 🎌 Waller — Live Wallpaper Engine for macOS

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/swift-5.9%2B-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" />
</p>

Transform your Mac desktop into a living, breathing canvas. **Waller** is a native macOS app that plays video wallpapers behind your desktop icons — with real-time **audio-reactive visualizer effects** that pulse to your music.

---

## ✨ Features

🎬 **Live Video Wallpapers** — Play any `.mp4`, `.mov`, `.mkv`, or `.webm` as your desktop wallpaper

🎌 **Built-in Anime Wallpaper Browser** — Browse and instantly download wallpapers from MoeWalls, with ad-blocking and clean UI

🔊 **Audio-Reactive Visualizer** — Your wallpaper pulses and blooms to the bass of your music using real-time DSP:
  - First-order IIR low-pass filter isolates bass/kick drums
  - vDSP-accelerated RMS computation (Accelerate framework)
  - CoreAudio system gate — only reacts when music is actually playing (ignores keyboard/talking)
  - Noise floor threshold kills ambient hum
  - Peak-hold envelope for satisfying visual "hang" on bass drops
  - Adjustable **Reaction Softness** slider (punchy ↔ cinematic)

⚡ **Smart Power Management** — Auto-pauses on battery and when apps go fullscreen

🌊 **Ambient Bloom Effect** — A blurred copy of your wallpaper glows behind it on bass drops, using the true colors of your video

🔇 **Tray-Only App** — Lives in your menu bar, zero Dock clutter

🚀 **Launch at Login** — Start automatically with your Mac

---

## 📦 Installation

### Download Pre-Built App

1. Go to [**Releases**](https://github.com/itsawaz/Waller/releases)
2. Download `Waller-v1.1.0-macOS.zip`
3. Unzip and drag `Waller.app` to your `/Applications` folder
4. Double-click to launch — look for the ▶︎ icon in your menu bar

> **Note:** The app is unsigned. On first launch, right-click → Open, then click "Open" in the dialog.

### Build from Source

```bash
git clone https://github.com/itsawaz/Waller.git
cd Waller/WallerNative
swift build -c release
sh build-app.sh
open Waller.app
```

**Requirements:** macOS 14+ · Swift 5.9+ · Xcode Command Line Tools

---

## 🎮 Usage

| Action | How |
|---|---|
| **Load a wallpaper** | Menu bar icon → Load Video Wallpaper… (⌘O) |
| **Browse anime wallpapers** | Menu bar icon → 🎌 Browse Anime Wallpapers… (⌘B) |
| **Settings** | Menu bar icon → Settings… (⌘,) |
| **Stop wallpaper** | Menu bar icon → Stop Wallpaper |
| **If icon is hidden by notch** | Press ⌘Space, type "Waller", hit Enter |

---

## 🔊 Audio Reactivity

Turn on **Audio Reactivity** in Settings to make your wallpaper pulse to music.

The engine uses your Mac's microphone to listen to system audio. A sophisticated DSP pipeline:

1. **IIR Low-Pass Filter** — Isolates bass frequencies (< 100Hz)
2. **vDSP RMS** — Hardware-accelerated volume measurement
3. **CoreAudio Gate** — Automatically silences when no music is playing
4. **Noise Floor** — Eliminates ambient room noise
5. **Peak Hold** — Latches onto bass hits for smooth visual decay
6. **Ambient Bloom** — Blurred background layer pulses with the wallpaper's own colors

Adjust the **Reaction Softness** slider:
- **Left** = Punchy, immediate response (EDM, hip-hop)
- **Right** = Cinematic, slow swells (lo-fi, ambient)

> **Requires:** Microphone permission. Keep Mic Mode set to "Standard" (not Voice Isolation).

---

## 🏗️ Architecture

```
WallerNative/
├── Sources/WallerNative/
│   ├── main.swift              # Entry point, sets .accessory policy
│   ├── AppDelegate.swift       # App lifecycle + Spotlight reopen handler
│   ├── WallpaperWindow.swift   # Core rendering: AVPlayerLayer + bloom effects
│   ├── AudioReactor.swift      # Real-time DSP: bass filter + envelope + CoreAudio gate
│   ├── StatusBarController.swift  # Menu bar icon + menu actions
│   ├── SettingsPanel.swift     # Native NSPanel with scrollable settings
│   ├── SettingsManager.swift   # UserDefaults persistence
│   ├── AboutPanel.swift        # Credits panel
│   ├── WallpaperBrowserPanel.swift  # WebKit browser with download interception
│   ├── PowerMonitor.swift      # Battery state monitoring
│   └── FullscreenMonitor.swift # Fullscreen app detection
├── Package.swift
├── Info.plist
└── build-app.sh                # Bundles into Waller.app
```

**Tech Stack:**
- Swift 5.9 · AppKit · AVFoundation · WebKit · CoreAudio · Accelerate (vDSP)
- SPM dependency: `sindresorhus/LaunchAtLogin-Modern`

---

## 📜 License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ♥ using Swift + AVFoundation
</p>
