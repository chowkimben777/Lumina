# Lumina

Lumina is a native macOS notch utility built with SwiftUI and AppKit. It blends into the MacBook notch when compact, expands on hover, and keeps everyday controls close to the top edge of the display.

> Lumina currently targets macOS 26 and Swift 6.2.

## Features

- Compact notch state with time, focus progress, or media status
- Hover expansion with spring animation
- Liquid Glass expanded surface on macOS 26
- Local clipboard history for text, links, and images
- Pin, restore, delete, pause recording, and clear clipboard entries
- Concealed pasteboard filtering for common password managers
- 25, 50, and 90 minute focus timers
- Music and Spotify metadata notifications and play/pause control
- Floating panel across Spaces and full-screen applications

## Requirements

- macOS 26 or later
- Xcode with Swift 6.2 support
- A MacBook display with a notch is recommended for the intended layout

## Getting Started

Open the package in Xcode:

```bash
open Package.swift
```

Select the `Lumina` executable scheme and choose Run.

To create a double-clickable app bundle from Terminal:

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open .build/Lumina.app
```

Clipboard history is saved locally under `~/Library/Application Support/Lumina/clipboard-history.json`. Right-click the island to quit the prototype.

## Project Structure

```text
Sources/Lumina/        SwiftUI and AppKit application source
Resources/            App bundle metadata
scripts/              Local build helpers
Package.swift         Swift Package manifest
```

## Privacy

Lumina stores clipboard history locally on your Mac and does not send clipboard contents to any remote service. Concealed pasteboard types used by common password managers are ignored.

## Roadmap

- User preferences for enabled modules and retention limits
- Keyboard shortcuts for opening modules
- Signed and notarized release artifacts
- Additional media player integrations

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

Lumina is available under the MIT License. See [LICENSE](LICENSE) for details.

## Notes

Music status is received from Apple Music and Spotify distributed notifications. Browsers and players that do not publish those notifications are not detected in this prototype.
