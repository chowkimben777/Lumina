import AppKit
import Foundation
import SwiftUI

struct IslandRootView: View {
  @Environment(IslandModel.self) private var model
  let onSizeChange: (CGSize) -> Void

  private var size: CGSize {
    switch model.presentation {
    case .compact:
      model.preferredCompactStatus == .idle
        ? IslandLayout.idleCompactSize
        : IslandLayout.activeCompactSize
    case .expanded: IslandLayout.expandedSize
    case .completion: IslandLayout.expandedSize
    case .module: IslandLayout.moduleSize
    }
  }

  private var shellShape: TopAttachedShape {
    switch model.presentation {
    case .compact:
      TopAttachedShape(topInset: 10, bottomRadius: 12)
    case .expanded:
      TopAttachedShape(topInset: 21, bottomRadius: 32)
    case .completion:
      TopAttachedShape(topInset: 21, bottomRadius: 32)
    case .module:
      TopAttachedShape(topInset: 21, bottomRadius: 34)
    }
  }

  var body: some View {
    islandBody
      .contentShape(Rectangle())
      .animation(
        .spring(response: 0.42, dampingFraction: 0.62), value: model.preferredCompactStatus
      )
      .onTapGesture(perform: model.handleIslandTap)
      .onAppear { onSizeChange(size) }
      .onChange(of: model.presentation) { _, _ in onSizeChange(size) }
      .onChange(of: model.preferredCompactStatus) { _, _ in onSizeChange(size) }
      .contextMenu {
        Button("退出 Lumina") { NSApp.terminate(nil) }
      }
  }

  private var islandBody: some View {
    ZStack(alignment: .top) {
      shellShape
        .fill(.black)
        .frame(width: size.width, height: size.height, alignment: .top)
        .overlay {
          shellShape.stroke(.white.opacity(0.05), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

      Group {
        switch model.presentation {
        case .compact:
          CompactIslandView(size: size)
        case .expanded:
          ExpandedIslandView()
        case .completion(let source):
          CompletionIslandView(source: source)
        case .module(let module):
          ModuleIslandView(module: module)
        }
      }
      // Keep content continuous, but never let it escape the animated shell.
      .frame(width: size.width, height: size.height, alignment: .top)
      .clipShape(shellShape)
      .opacity(model.showsPresentationContent ? 1 : 0)
    }
    .frame(
      width: size.width + IslandLayout.shadowPadding * 2,
      height: size.height + IslandLayout.shadowPadding,
      alignment: .top
    )
  }

}

private struct IslandShell<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(.top, IslandLayout.menuBarHeight + 5)
      .padding(.horizontal, 32)
      .padding(.bottom, 10)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

private struct TopAttachedShape: Shape {
  var topInset: CGFloat
  var bottomRadius: CGFloat

  var animatableData: AnimatablePair<CGFloat, CGFloat> {
    get { AnimatablePair(topInset, bottomRadius) }
    set {
      topInset = newValue.first
      bottomRadius = newValue.second
    }
  }

  func path(in rect: CGRect) -> Path {
    Self.path(in: rect, topInset: topInset, bottomRadius: bottomRadius)
  }

  static func path(in rect: CGRect, topInset: CGFloat, bottomRadius: CGFloat) -> Path {
    let inset = min(topInset, rect.width / 4, rect.height / 3)
    let lowerRadius = min(bottomRadius, rect.height - inset, rect.width / 4)
    let circleControl = lowerRadius * 0.552_284_8

    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addCurve(
      to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset),
      control1: CGPoint(x: rect.maxX - inset * 0.55, y: rect.minY),
      control2: CGPoint(x: rect.maxX - inset, y: rect.minY + inset * 0.45)
    )
    path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - lowerRadius))
    path.addCurve(
      to: CGPoint(x: rect.maxX - inset - lowerRadius, y: rect.maxY),
      control1: CGPoint(
        x: rect.maxX - inset,
        y: rect.maxY - lowerRadius + circleControl
      ),
      control2: CGPoint(
        x: rect.maxX - inset - lowerRadius + circleControl,
        y: rect.maxY
      )
    )
    path.addLine(to: CGPoint(x: rect.minX + inset + lowerRadius, y: rect.maxY))
    path.addCurve(
      to: CGPoint(x: rect.minX + inset, y: rect.maxY - lowerRadius),
      control1: CGPoint(
        x: rect.minX + inset + lowerRadius - circleControl,
        y: rect.maxY
      ),
      control2: CGPoint(
        x: rect.minX + inset,
        y: rect.maxY - lowerRadius + circleControl
      )
    )
    path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
    path.addCurve(
      to: CGPoint(x: rect.minX, y: rect.minY),
      control1: CGPoint(x: rect.minX + inset, y: rect.minY + inset * 0.45),
      control2: CGPoint(x: rect.minX + inset * 0.55, y: rect.minY)
    )
    path.closeSubpath()
    return path
  }
}

private struct CompactIslandView: View {
  @Environment(IslandModel.self) private var model
  let size: CGSize

  var body: some View {
    Group {
      if model.preferredCompactStatus == .idle {
        Color.clear
      } else {
        HStack(spacing: 0) {
          statusLeading
            .frame(width: IslandLayout.compactSideWidth)

          Color.clear.frame(width: IslandLayout.notchWidth)

          statusTrailing
            .fixedSize(horizontal: true, vertical: false)
            .frame(width: IslandLayout.compactSideWidth)
        }
      }
    }
    .frame(width: size.width, height: size.height)
    .foregroundStyle(.white)
  }

  @ViewBuilder
  private var statusLeading: some View {
    switch model.preferredCompactStatus {
    case .focus:
      Circle()
        .trim(from: 0, to: max(0.02, model.focus.progress))
        .stroke(.mint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .frame(width: 15, height: 15)
    case .media:
      PlayingWaveform(isPlaying: model.media.isPlaying)
    case .idle:
      Image(systemName: "sparkle")
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var statusTrailing: some View {
    switch model.preferredCompactStatus {
    case .focus:
      Text(model.focus.formattedTime)
        .monospacedDigit()
        .font(.system(size: 12, weight: .semibold))
    case .media:
      Image(systemName: model.media.isPlaying ? "pause.fill" : "play.fill")
        .font(.system(size: 10, weight: .bold))
    case .idle:
      EmptyView()
    }
  }
}

private struct PlayingWaveform: View {
  let isPlaying: Bool
  private let baseHeights: [CGFloat] = [7, 11, 15, 11, 7]

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: !isPlaying)) { context in
      let time = context.date.timeIntervalSinceReferenceDate
      HStack(alignment: .center, spacing: 1.5) {
        ForEach(baseHeights.indices, id: \.self) { index in
          RoundedRectangle(cornerRadius: 1.2, style: .continuous)
            .fill(.cyan)
            .frame(width: 2, height: barHeight(at: index, time: time))
        }
      }
      .frame(width: 16, height: 17)
    }
    .accessibilityLabel(isPlaying ? "正在播放" : "已暂停")
  }

  private func barHeight(at index: Int, time: TimeInterval) -> CGFloat {
    guard isPlaying else { return baseHeights[index] * 0.45 }
    let phase = time * 5.4 + Double(index) * 1.37
    let amplitude = 0.38 + 0.62 * abs(sin(phase))
    return max(3, baseHeights[index] * amplitude)
  }
}

private struct ExpandedIslandView: View {
  @Environment(IslandModel.self) private var model

  var body: some View {
    IslandShell {
      VStack(spacing: 8) {
        activeStatus
          .frame(height: 42)

        Divider().overlay(.white.opacity(0.08))

        HStack(spacing: 10) {
          ForEach(IslandModule.allCases) { module in
            Button {
              model.open(module)
            } label: {
              VStack(spacing: 5) {
                Image(systemName: module.symbol)
                  .font(.system(size: 14, weight: .semibold))
                Text(module.title)
                  .font(.system(size: 10, weight: .medium))
              }
              .frame(maxWidth: .infinity)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.84))
            .help(module.title)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var activeStatus: some View {
    switch model.preferredCompactStatus {
    case .focus:
      FocusStatusRow()
    case .media:
      MediaStatusRow()
    case .idle:
      HStack(spacing: 12) {
        Image(systemName: "sparkles")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.cyan)
        VStack(alignment: .leading, spacing: 2) {
          Text("准备好了")
            .font(.system(size: 14, weight: .semibold))
          Text("选择一个功能开始")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .foregroundStyle(.white)
    }
  }
}

private struct CompletionIslandView: View {
  let source: AICompletionSource

  var body: some View {
    IslandShell {
      HStack(spacing: 13) {
        ZStack {
          Circle()
            .fill(.cyan.opacity(0.16))
            .frame(width: 38, height: 38)
          Image(systemName: source.symbol)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.cyan)
        }

        VStack(alignment: .leading, spacing: 3) {
          Text(source.title)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
          Text("任务已完成，可以回来看看了")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.56))
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 12)
      .frame(maxHeight: .infinity, alignment: .center)
    }
  }
}

private struct ModuleIslandView: View {
  @Environment(IslandModel.self) private var model
  let module: IslandModule

  var body: some View {
    IslandShell {
      VStack(spacing: 14) {
        HStack {
          Button(action: model.closeModule) {
            Image(systemName: "chevron.left")
              .frame(width: 38, height: 38)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .help("返回")

          Label(module.title, systemImage: module.symbol)
            .font(.system(size: 14, weight: .semibold))

          Spacer()
        }
        .foregroundStyle(.white.opacity(0.9))

        Group {
          switch module {
          case .clipboard: ClipboardModuleView()
          case .focus: FocusModuleView()
          case .media: MediaModuleView()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }
}

private struct FocusStatusRow: View {
  @Environment(IslandModel.self) private var model

  var body: some View {
    HStack(spacing: 12) {
      ProgressView(value: model.focus.progress)
        .progressViewStyle(.circular)
        .tint(.mint)
        .frame(width: 34, height: 34)
      VStack(alignment: .leading, spacing: 2) {
        Text(model.focus.isPaused ? "专注已暂停" : "正在专注")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.secondary)
        Text(model.focus.formattedTime)
          .monospacedDigit()
          .font(.system(size: 20, weight: .semibold))
      }
      Spacer()
      Button(action: model.focus.togglePause) {
        Image(systemName: model.focus.isRunning ? "pause.fill" : "play.fill")
          .frame(width: 52, height: 36)
          .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(.white.opacity(0.08))
          }
          .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .stroke(.white.opacity(0.12), lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .help(model.focus.isRunning ? "暂停" : "继续")

      Button(action: model.focus.stop) {
        Image(systemName: "stop.fill")
          .frame(width: 52, height: 36)
          .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(.white.opacity(0.08))
          }
          .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .stroke(.white.opacity(0.12), lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .foregroundStyle(.white.opacity(0.76))
      .help("停止专注")
    }
    .foregroundStyle(.white)
  }
}

private struct MediaStatusRow: View {
  @Environment(IslandModel.self) private var model

  var body: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 9)
        .fill(.cyan.opacity(0.22))
        .overlay(Image(systemName: "music.note").foregroundStyle(.cyan))
        .frame(width: 42, height: 42)
      VStack(alignment: .leading, spacing: 3) {
        Text(model.media.title ?? "没有正在播放的内容")
          .font(.system(size: 13, weight: .semibold))
          .lineLimit(1)
        Text(model.media.artist ?? model.media.source ?? "Music 或 Spotify")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer()
      Button(action: model.media.togglePlayback) {
        Image(systemName: model.media.isPlaying ? "pause.fill" : "play.fill")
          .frame(width: 28, height: 28)
      }
      .buttonStyle(.glass)
      .disabled(model.media.isChangingPlayback)
      .help(model.media.isPlaying ? "暂停" : "播放")
    }
    .foregroundStyle(.white)
  }
}
