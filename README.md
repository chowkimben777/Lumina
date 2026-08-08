# Lumina

> A native macOS notch companion for clipboard history, focus sessions, media controls, and AI completion alerts.

[简体中文](README.zh-CN.md)

Lumina sits flush with a MacBook's notch while idle. Move the pointer over the notch to expand a top-anchored Dynamic Island with the controls you use most often.

## Highlights

- **Notch-first interface**: stays visually integrated with the notch and expands with a spring motion while keeping its top edge anchored.
- **Clipboard history**: keeps local text, link, and image history with restore, pin, delete, and clear actions.
- **Focus timer**: start 25, 50, or 90 minute sessions; pause, resume, or stop directly from the island.
- **Scheduled reminders**: create named reminders for a specific time, once, daily, or on weekdays. A due reminder expands the island for five seconds.
- **Media status**: reads Apple Music and Spotify notifications, plus experimental QQ Music display and play/pause control on macOS 26.
- **AI completion alerts**: notices when Codex or Trae finishes a substantial task while you are using another app, expands the island for three seconds, and lets you click back to the source app.
- **Native macOS behavior**: built with SwiftUI and AppKit; available across Spaces and full-screen apps.

## Requirements

- macOS 26 or later to run a release build
- A notched MacBook display is recommended
- Xcode with Swift 6.2 support only when building from source

## Getting Started

### Xcode

```bash
open Package.swift
```

Choose the `Lumina` executable scheme in Xcode and run it.

### Terminal

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open .build/Lumina.app
```

The app bundle is created at `.build/Lumina.app`.

## Releases

Download the archive matching your Mac from the repository's [Releases](../../releases) page. A release build does not require Xcode.

1. Download and unzip `Lumina-v*-macos-arm64.zip` for Apple silicon Macs, or the matching `x86_64` archive for Intel Macs.
2. Drag `Lumina.app` to `/Applications` or any preferred folder.
3. On the first launch, **Control-click > Open** and confirm in macOS. The app is currently unsigned and has not been notarized.

To create a local release archive for the current Mac architecture:

```bash
scripts/package-release.sh v0.1.0
```

The command writes a ZIP archive and SHA-256 checksum to `dist/`. Pushing a Git tag that begins with `v` runs the same packaging step in GitHub Actions and creates a GitHub Release automatically.

## Usage

1. Move the pointer into the notch area to open the main island.
2. Select **Clipboard** to browse and restore local history.
3. Select **Focus** to start a timer. When one is running, pause, resume, or stop it from the expanded island.
4. Select **Reminders** to create, edit, enable, or remove one-time, daily, and weekday reminders.
5. Media remains available automatically: when something is playing, the island shows its status and offers play/pause without a separate module.
6. When Codex or Trae completes a tool task or a longer response while it is not frontmost, Lumina shows a completion alert for three seconds. Click the alert to return to the matching app.
7. Move the pointer away from the panel to collapse it. Right-click the island to quit.

## Data and Privacy

Clipboard history is stored locally at:

```text
~/Library/Application Support/Lumina/clipboard-history.json
```

Lumina does not upload clipboard data. Reminder tasks are stored locally in macOS preferences. It ignores concealed pasteboard types commonly used by password managers. The AI completion alert reads local Codex session events and Trae agent activity only; it does not send task content or activity data anywhere. QQ Music support uses a macOS 26 system-media bridge. It is experimental because Apple does not offer a public API for third-party apps to read system-wide media metadata.

## Development

```text
Sources/Lumina/   SwiftUI and AppKit source
Resources/        App bundle metadata
scripts/          Local build helpers
Package.swift     Swift Package manifest
```

Before opening a pull request, format and build the project:

```bash
xcrun swift-format format --in-place --recursive Sources Package.swift
./scripts/build-app.sh
xcrun swift-format lint --recursive Sources Package.swift
```

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md) before participating.

## Roadmap

- Preferences for enabled modules and retention limits
- Global shortcuts
- Signed and notarized release artifacts
- More media player integrations

## License

Lumina is released under the [MIT License](LICENSE).
