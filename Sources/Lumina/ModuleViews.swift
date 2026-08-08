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
      .disabled(model.media.isChangingPlayback)
      .help(model.media.isPlaying ? "暂停" : "播放")
      Spacer()
    }
    .foregroundStyle(.white)
  }
}

struct ReminderModuleView: View {
  @Environment(IslandModel.self) private var model
  @State private var isEditing = false
  @State private var editingID: UUID?
  @State private var title = ""
  @State private var time = Date()
  @State private var frequency: ReminderFrequency = .once
  @State private var isEnabled = true

  var body: some View {
    Group {
      if isEditing {
        editor
      } else {
        taskList
      }
    }
    .foregroundStyle(.white)
  }

  private var taskList: some View {
    VStack(spacing: 10) {
      HStack {
        Text("提醒任务")
          .font(.system(size: 12, weight: .semibold))
        Spacer()
        Button(action: beginNewTask) {
          Image(systemName: "plus")
            .frame(width: 32, height: 28)
        }
        .buttonStyle(.glass)
        .help("新建提醒")
      }

      if model.reminders.tasks.isEmpty {
        ContentUnavailableView(
          "还没有提醒",
          systemImage: "bell",
          description: Text("添加一个时间，到点后 Lumina 会提醒你")
        )
      } else {
        ScrollView {
          LazyVStack(spacing: 6) {
            ForEach(model.reminders.tasks) { task in
              taskRow(task)
            }
          }
        }
        .scrollIndicators(.hidden)
      }
    }
    .padding(.horizontal, 14)
  }

  private func taskRow(_ task: ReminderTask) -> some View {
    HStack(spacing: 10) {
      Image(systemName: task.isEnabled ? "bell.fill" : "bell.slash")
        .foregroundStyle(task.isEnabled ? .orange : .secondary)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(task.title)
          .font(.system(size: 12, weight: .semibold))
          .lineLimit(1)
        Text(task.scheduleText)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)

      HStack(spacing: 2) {
        Toggle(
          "",
          isOn: Binding(
            get: { task.isEnabled },
            set: { _ in model.reminders.toggle(task) }
          )
        )
        .labelsHidden()
        .toggleStyle(.switch)
        .controlSize(.mini)

        Button {
          beginEditing(task)
        } label: {
          Image(systemName: "pencil")
            .frame(width: 36, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("编辑提醒")

        Button(role: .destructive) {
          model.reminders.delete(task)
        } label: {
          Image(systemName: "trash")
            .frame(width: 36, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red.opacity(0.82))
        .help("删除提醒")
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 7)
    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    .contextMenu {
      Button("编辑") { beginEditing(task) }
      Button("删除", role: .destructive) { model.reminders.delete(task) }
    }
  }

  private var editor: some View {
    VStack(alignment: .leading, spacing: 13) {
      Text(editingID == nil ? "新建提醒" : "编辑提醒")
        .font(.system(size: 14, weight: .semibold))

      TextField(
        "",
        text: $title,
        prompt: Text("提醒内容").foregroundStyle(.black.opacity(0.42))
      )
      .textFieldStyle(.plain)
      .foregroundStyle(.black)
      .tint(.blue)
      .padding(.horizontal, 10)
      .frame(height: 36)
      .background(.white, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

      DatePicker("提醒时间", selection: $time, displayedComponents: .hourAndMinute)
        .datePickerStyle(.field)
        .font(.system(size: 12, weight: .semibold))
        .controlSize(.small)

      HStack(spacing: 7) {
        Text("重复")
          .font(.system(size: 11, weight: .semibold))
          .frame(width: 42, alignment: .leading)

        ForEach(ReminderFrequency.allCases) { option in
          Button {
            frequency = option
          } label: {
            Text(option.title)
              .font(.system(size: 10, weight: .semibold))
              .frame(maxWidth: .infinity)
              .frame(height: 28)
              .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
          }
          .buttonStyle(.plain)
          .foregroundStyle(frequency == option ? .black : .white.opacity(0.78))
          .background(
            frequency == option ? .orange : .white.opacity(0.075),
            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
          )
        }
      }

      Toggle(isOn: $isEnabled) {
        Text("启用提醒")
          .font(.system(size: 12, weight: .semibold))
      }
      .toggleStyle(.switch)
      .controlSize(.small)

      Spacer(minLength: 0)

      HStack(spacing: 8) {
        Button(action: cancelEditing) {
          Label("取消", systemImage: "xmark")
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 94)
            .frame(height: 32)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.86))
        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

        Spacer()

        Button(action: saveTask) {
          Label("保存", systemImage: "checkmark")
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 94)
            .frame(height: 32)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(.orange, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
      .padding(6)
      .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
      .padding(.bottom, 12)
    }
    .padding(.horizontal, 14)
    .padding(.bottom, 10)
  }

  private func beginNewTask() {
    editingID = nil
    title = ""
    time = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
    frequency = .once
    isEnabled = true
    isEditing = true
  }

  private func beginEditing(_ task: ReminderTask) {
    editingID = task.id
    title = task.title
    time =
      Calendar.current.date(from: DateComponents(hour: task.hour, minute: task.minute)) ?? Date()
    frequency = task.frequency
    isEnabled = task.isEnabled
    isEditing = true
  }

  private func cancelEditing() {
    isEditing = false
  }

  private func saveTask() {
    let components = Calendar.current.dateComponents([.hour, .minute], from: time)
    model.reminders.save(
      id: editingID,
      title: title,
      hour: components.hour ?? 9,
      minute: components.minute ?? 0,
      frequency: frequency,
      isEnabled: isEnabled
    )
    isEditing = false
  }
}
