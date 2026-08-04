# Lumina

> A native macOS notch companion for clipboard history, focus sessions, and media controls.

[简体中文](README.zh-CN.md)

Lumina sits flush with a MacBook's notch while idle. Move the pointer over the notch to expand a top-anchored Dynamic Island with the controls you use most often.

## Highlights

- **Notch-first interface**: stays visually integrated with the notch and expands with a spring motion while keeping its top edge anchored.
- **Clipboard history**: keeps local text, link, and image history with restore, pin, delete, and clear actions.
- **Focus timer**: start 25, 50, or 90 minute sessions; pause, resume, or stop directly from the island.
- **Media status**: reads Apple Music and Spotify distributed notifications and exposes playback control when available.
- **Native macOS behavior**: built with SwiftUI and AppKit; available across Spaces and full-screen apps.

## Requirements

- macOS 26 or later
- Xcode with Swift 6.2 support
- A notched MacBook display is recommended

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

## Usage

1. Move the pointer into the notch area to open the main island.
2. Select **Clipboard** to browse and restore local history.
3. Select **Focus** to start a timer. When one is running, pause, resume, or stop it from the expanded island.
4. Select **Media** to view the current media state.
5. Move the pointer away from the panel to collapse it. Right-click the island to quit.

## Data and Privacy

Clipboard history is stored locally at:

```text
~/Library/Application Support/Lumina/clipboard-history.json
```

Lumina does not upload clipboard data. It ignores concealed pasteboard types commonly used by password managers. Media support depends on local distributed notifications from Apple Music and Spotify; players that do not publish these notifications are not detected.

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
