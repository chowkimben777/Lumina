import Foundation
import Observation

enum ReminderFrequency: String, Codable, CaseIterable, Identifiable, Hashable {
  case once
  case daily
  case weekdays

  var id: String { rawValue }

  var title: String {
    switch self {
    case .once: "仅一次"
    case .daily: "每天"
    case .weekdays: "工作日"
    }
  }
}

struct ReminderTask: Codable, Identifiable, Hashable {
  var id = UUID()
  var title: String
  var hour: Int
  var minute: Int
  var frequency: ReminderFrequency
  var isEnabled: Bool
  var lastTriggeredAt: Date?

  var timeText: String {
    String(format: "%02d:%02d", hour, minute)
  }

  var scheduleText: String {
    "\(frequency.title) \(timeText)"
  }
}

@MainActor
@Observable
final class ReminderStore {
  private enum StorageKey {
    static let tasks = "reminder.tasks"
  }

  var tasks: [ReminderTask] = []
  var onReminder: ((ReminderTask) -> Void)?
  private var timer: Timer?
  private let calendar = Calendar.current

  init() {
    load()
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.checkDueTasks() }
    }
  }

  func save(
    id: UUID?, title: String, hour: Int, minute: Int, frequency: ReminderFrequency, isEnabled: Bool
  ) {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let taskTitle = trimmedTitle.isEmpty ? "提醒事项" : trimmedTitle
    if let id, let index = tasks.firstIndex(where: { $0.id == id }) {
      tasks[index].title = taskTitle
      tasks[index].hour = hour
      tasks[index].minute = minute
      tasks[index].frequency = frequency
      tasks[index].isEnabled = isEnabled
      tasks[index].lastTriggeredAt = nil
    } else {
      tasks.insert(
        ReminderTask(
          title: taskTitle,
          hour: hour,
          minute: minute,
          frequency: frequency,
          isEnabled: isEnabled
        ),
        at: 0
      )
    }
    persist()
  }

  func toggle(_ task: ReminderTask) {
    guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
    tasks[index].isEnabled.toggle()
    persist()
  }

  func delete(_ task: ReminderTask) {
    tasks.removeAll { $0.id == task.id }
    persist()
  }

  private func checkDueTasks() {
    let now = Date()
    let components = calendar.dateComponents([.hour, .minute, .weekday], from: now)
    guard let hour = components.hour, let minute = components.minute else { return }

    for index in tasks.indices where tasks[index].isEnabled {
      guard tasks[index].hour == hour, tasks[index].minute == minute,
        matchesFrequency(tasks[index].frequency, weekday: components.weekday)
      else { continue }
      guard !wasTriggeredThisMinute(tasks[index], now: now) else { continue }

      tasks[index].lastTriggeredAt = now
      if tasks[index].frequency == .once {
        tasks[index].isEnabled = false
      }
      let task = tasks[index]
      persist()
      onReminder?(task)
    }
  }

  private func matchesFrequency(_ frequency: ReminderFrequency, weekday: Int?) -> Bool {
    switch frequency {
    case .once, .daily:
      return true
    case .weekdays:
      guard let weekday else { return false }
      return weekday != 1 && weekday != 7
    }
  }

  private func wasTriggeredThisMinute(_ task: ReminderTask, now: Date) -> Bool {
    guard let lastTriggeredAt = task.lastTriggeredAt else { return false }
    return calendar.isDate(lastTriggeredAt, equalTo: now, toGranularity: .minute)
  }

  private func load() {
    guard let data = UserDefaults.standard.data(forKey: StorageKey.tasks),
      let decoded = try? JSONDecoder().decode([ReminderTask].self, from: data)
    else { return }
    tasks = decoded
  }

  private func persist() {
    guard let data = try? JSONEncoder().encode(tasks) else { return }
    UserDefaults.standard.set(data, forKey: StorageKey.tasks)
  }
}
