import AppKit
import Observation
import SwiftUI

enum IslandModule: String, CaseIterable, Identifiable {
  case clipboard
  case focus
  case media

  var id: String { rawValue }

  var title: String {
    switch self {
    case .clipboard: "剪贴板"
    case .focus: "专注"
    case .media: "媒体"
    }
  }

  var symbol: String {
    switch self {
    case .clipboard: "clipboard"
    case .focus: "timer"
    case .media: "waveform"
    }
  }
}

enum IslandPresentation: Equatable {
  case compact
  case expanded
  case module(IslandModule)
}

enum IslandLayout {
  static let compactSideWidth: CGFloat = 72
  static let topAttachmentOverscan: CGFloat = 4

  static var notchScreen: NSScreen? {
    NSScreen.screens.first {
      $0.auxiliaryTopLeftArea != nil && $0.auxiliaryTopRightArea != nil
    } ?? NSScreen.main ?? NSScreen.screens.first
  }

  static var notchWidth: CGFloat {
    guard let screen = notchScreen,
      let leftArea = screen.auxiliaryTopLeftArea,
      let rightArea = screen.auxiliaryTopRightArea
    else { return 185 }
    return max(140, rightArea.minX - leftArea.maxX)
  }

  static var menuBarHeight: CGFloat {
    let screen = notchScreen
    return max(28, screen?.safeAreaInsets.top ?? 32)
  }

  static var notchHeight: CGFloat {
    guard let screen = notchScreen,
      let leftArea = screen.auxiliaryTopLeftArea,
      let rightArea = screen.auxiliaryTopRightArea
    else { return menuBarHeight }
    return min(leftArea.height, rightArea.height)
  }

  static var compactSize: CGSize {
    idleCompactSize
  }

  static var idleCompactSize: CGSize {
    CGSize(width: notchWidth, height: notchHeight + topAttachmentOverscan)
  }

  static var activeCompactSize: CGSize {
    CGSize(
      width: notchWidth + compactSideWidth * 2,
      height: notchHeight + topAttachmentOverscan
    )
  }

  static let expandedSize = CGSize(width: 380, height: 142)
  static let moduleSize = CGSize(width: 420, height: 360)
  static let panelSize = moduleSize
}

@MainActor
@Observable
final class IslandModel {
  var presentation: IslandPresentation = .compact
  let clipboard = ClipboardHistoryStore()
  let focus = FocusTimerModel()
  let media = MediaNowPlayingModel()
  private var isPointerInside = false
  private var transitionTask: Task<Void, Never>?

  var preferredCompactStatus: CompactStatus {
    if focus.isRunning || focus.isPaused {
      return .focus
    }
    if media.isPlaying || media.title != nil {
      return .media
    }
    return .idle
  }

  func hoverChanged(_ hovering: Bool) {
    isPointerInside = hovering
    transitionTask?.cancel()

    if hovering {
      guard presentation == .compact else { return }
      withAnimation(.linear(duration: 0.18)) {
        presentation = .expanded
      }
    } else {
      guard isAutoCollapsible else { return }
      beginCollapse()
    }
  }

  func open(_ module: IslandModule) {
    withAnimation(.linear(duration: 0.2)) {
      presentation = .module(module)
    }
  }

  func expand() {
    guard presentation == .compact else { return }
    isPointerInside = true
    transitionTask?.cancel()
    withAnimation(.linear(duration: 0.18)) {
      presentation = .expanded
    }
  }

  func closeModule() {
    withAnimation(.linear(duration: 0.2)) {
      presentation = .expanded
    }
  }

  func collapse() {
    isPointerInside = false
    transitionTask?.cancel()
    beginCollapse(delay: .zero)
  }

  private func beginCollapse(delay: Duration = .milliseconds(140)) {
    transitionTask = Task {
      try? await Task.sleep(for: delay)
      guard !Task.isCancelled, !self.isPointerInside, self.isAutoCollapsible else { return }
      withAnimation(.linear(duration: 0.16)) {
        self.presentation = .compact
      }
    }
  }

  private var isAutoCollapsible: Bool {
    switch presentation {
    case .expanded, .module:
      true
    case .compact:
      false
    }
  }
}

enum CompactStatus: Equatable {
  case idle
  case focus
  case media
}
