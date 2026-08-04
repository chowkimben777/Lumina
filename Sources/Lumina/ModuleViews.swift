import AppKit
import SwiftUI

struct ClipboardModuleView: View {
  @Environment(IslandModel.self) private var model

  var body: some View {
    VStack(spacing: 10) {
      HStack {
        Text("最近 \(model.clipboard.entries.count) 条")
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.secondary)
        Spacer()
        Button(action: model.clipboard.clearUnpinned) {
          Image(systemName: "trash")
        }
        .buttonStyle(.plain)
        .help("清空未置顶内容")
      }
      .foregroundStyle(.white.opacity(0.76))

      if model.clipboard.entries.isEmpty {
        ContentUnavailableView(
          "还没有剪贴内容",
          systemImage: "clipboard",
          description: Text("复制文字、链接或图片后会出现在这里")
        )
      } else {
        ScrollView {
          LazyVStack(spacing: 1) {
            ForEach(model.clipboard.entries) { entry in
              ClipboardEntryRow(entry: entry)
            }
          }
        }
        .scrollIndicators(.hidden)
      }
    }
  }
}

private struct ClipboardEntryRow: View {
  @Environment(IslandModel.self) private var model
  let entry: ClipboardEntry

  var body: some View {
    Button {
      model.clipboard.restore(entry)
      model.collapse()
    } label: {
      HStack(spacing: 11) {
        Group {
          if entry.kind == .image, let data = entry.imageData, let image = NSImage(data: data) {
            Image(nsImage: image)
              .resizable()
              .scaledToFill()
          } else {
            Image(systemName: entry.text?.hasPrefix("http") == true ? "link" : "text.alignleft")
              .foregroundStyle(.cyan)
          }
        }
        .frame(width: 32, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 7))

        Text(entry.displayText)
          .font(.system(size: 12, weight: .medium))
          .lineLimit(2)
          .multilineTextAlignment(.leading)
        Spacer(minLength: 4)
        if entry.isPinned {
          Image(systemName: "pin.fill")
            .font(.system(size: 10))
            .foregroundStyle(.yellow)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 7)
      .contentShape(RoundedRectangle(cornerRadius: 9))
    }
    .buttonStyle(.plain)
    .foregroundStyle(.white.opacity(0.9))
    .contextMenu {
      Button(entry.isPinned ? "取消置顶" : "置顶") { model.clipboard.togglePinned(entry) }
      Button("删除", role: .destructive) { model.clipboard.delete(entry) }
    }
  }
}

struct FocusModuleView: View {
  @Environment(IslandModel.self) private var model

  var body: some View {
    VStack(spacing: 24) {
      Spacer(minLength: 4)
      ZStack {
        Circle()
          .stroke(.white.opacity(0.1), lineWidth: 8)
        Circle()
          .trim(
            from: 0, to: model.focus.isRunning || model.focus.isPaused ? model.focus.progress : 0
          )
          .stroke(.mint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
          .rotationEffect(.degrees(-90))
        VStack(spacing: 3) {
          Text(model.focus.formattedTime)
            .font(.system(size: 32, weight: .semibold, design: .rounded))
            .monospacedDigit()
          Text(model.focus.isRunning ? "正在专注" : model.focus.isPaused ? "已暂停" : "选择时长")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: 142, height: 142)

      if model.focus.isRunning || model.focus.isPaused {
        HStack(spacing: 12) {
          Button(action: model.focus.togglePause) {
            Label(
              model.focus.isRunning ? "暂停" : "继续",
              systemImage: model.focus.isRunning ? "pause.fill" : "play.fill")
          }
          .buttonStyle(.glassProminent)
          .tint(.mint)
          Button(action: model.focus.stop) {
            Label("结束", systemImage: "stop.fill")
          }
          .buttonStyle(.glass)
        }
      } else {
        HStack(spacing: 10) {
          ForEach([25, 50, 90], id: \.self) { minutes in
            Button("\(minutes) 分钟") { model.focus.start(minutes: minutes) }
              .buttonStyle(.glass)
          }
        }
      }
      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
  }
}

struct MediaModuleView: View {
  @Environment(IslandModel.self) private var model

  var body: some View {
    VStack(spacing: 12) {
      Spacer()
      RoundedRectangle(cornerRadius: 22)
        .fill(.cyan.opacity(0.18))
        .overlay(
          Image(systemName: "music.note")
            .font(.system(size: 34, weight: .medium))
            .foregroundStyle(.cyan)
        )
        .frame(width: 108, height: 108)

      VStack(spacing: 5) {
        Text(model.media.title ?? "没有正在播放的内容")
          .font(.system(size: 17, weight: .semibold))
          .lineLimit(1)
        Text(model.media.artist ?? model.media.source ?? "支持 Music 与 Spotify")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Button(action: model.media.togglePlayback) {
        Image(systemName: model.media.isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 17, weight: .bold))
          .frame(width: 42, height: 34)
      }
      .buttonStyle(.glassProminent)
      .tint(.cyan)
      .help(model.media.isPlaying ? "暂停" : "播放")
      Spacer()
    }
    .foregroundStyle(.white)
  }
}
