# Contributing

Thanks for taking the time to improve Lumina.

## Development

1. Install Xcode with Swift 6.2 support.
2. Clone the repository.
3. Open `Package.swift` in Xcode, or build from Terminal:

```bash
swift build
```

You can also create a local app bundle:

```bash
./scripts/build-app.sh
```

## Pull Requests

- Keep changes focused and easy to review.
- Include screenshots or short screen recordings for visible UI changes.
- Update `README.md` when behavior, requirements, or user-facing workflows change.
- Run `swift build` before opening a pull request.

## Style

Lumina uses two-space indentation for Swift source. Prefer small SwiftUI views and focused model objects over broad shared abstractions.

## Reporting Issues

Please include:

- macOS and Xcode versions
- Mac model
- Steps to reproduce
- Expected and actual behavior
- Screenshots or logs when useful
