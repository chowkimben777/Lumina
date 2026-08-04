import AppKit
import Observation
import SwiftUI

enum IslandModule: String, CaseIterable, Identifiable, Hashable {
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

enum IslandPresentation: Equatable, Hashable {
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
  // A Gaussian shadow remains visible for roughly three times its blur radius.
  // Keep that falloff inside the transparent panel instead of clipping it.
  static let shadowPadding: CGFloat = 48
  static func panelSize(for islandSize: CGSize) -> CGSize {
    CGSize(
      width: islandSize.width + shadowPadding * 2,
      height: islandSize.height + shadowPadding
    )
  }

  static let panelSize = panelSize(for: moduleSize)
}

@MainActor
@Observable
final class IslandModel {
  var presentation: IslandPresentation = .compact
  var showsPresentationContent = true
  let clipboard = ClipboardHistoryStore()
  let focus = FocusTimerModel()
  let media = MediaNowPlayingModel()
  private var isPointerInside = false
  private var transitionTask: Task<Void, Never>?
  private var contentTask: Task<Void, Never>?
  private let expansionAnimation = Animation.spring(response: 0.46, dampingFraction: 0.58)
  private let moduleAnimation = Animation.spring(response: 0.46, dampingFraction: 0.62)
  private let collapseAnimation = Animation.spring(response: 0.32, dampingFraction: 0.8)

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
      transition(to: .expanded, animation: expansionAnimation)
    } else {
      guard isAutoCollapsible else { return }
      beginCollapse()
    }
  }

  func open(_ module: IslandModule) {
    transition(to: .module(module), animation: moduleAnimation)
  }

  func expand() {
    guard presentation == .compact else { return }
    isPointerInside = true
    transitionTask?.cancel()
    transition(to: .expanded, animation: expansionAnimation)
  }

  func closeModule() {
    transition(to: .expanded, animation: moduleAnimation)
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
      self.transition(to: .compact, animation: self.collapseAnimation)
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

  private func transition(to destination: IslandPresentation, animation: Animation) {
    contentTask?.cancel()

    if destination == .compact {
      showsPresentationContent = false
      withAnimation(animation) {
        presentation = destination
      }
      contentTask = Task {
        try? await Task.sleep(for: .milliseconds(360))
        guard !Task.isCancelled else { return }
        self.showsPresentationContent = true
      }
      return
    }

    showsPresentationContent = false
    withAnimation(animation) {
      presentation = destination
    }
    contentTask = Task {
      try? await Task.sleep(for: .milliseconds(80))
      guard !Task.isCancelled else { return }
      withAnimation(.linear(duration: 0.22)) {
        self.showsPresentationContent = true
      }
    }
  }
}

enum CompactStatus: Equatable {
  case idle
  case focus
  case media
}
