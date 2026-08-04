import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class FocusTimerModel {
  private enum StorageKey {
    static let totalSeconds = "focusTimer.totalSeconds"
    static let targetDate = "focusTimer.targetDate"
    static let pausedSeconds = "focusTimer.pausedSeconds"
  }

  private(set) var remainingSeconds = 25 * 60
  private(set) var totalSeconds = 25 * 60
  private(set) var isRunning = false
  private(set) var isPaused = false
  private var timer: Timer?
  private var targetDate: Date?

  init() {
    restorePersistedTimer()
  }

  var progress: Double {
    guard totalSeconds > 0 else { return 0 }
    return 1 - Double(remainingSeconds) / Double(totalSeconds)
  }

  var formattedTime: String {
    String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
  }

  func start(minutes: Int) {
    totalSeconds = minutes * 60
    remainingSeconds = totalSeconds
    isRunning = true
    isPaused = false
    targetDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
    clearPausedTimer()
    persistRunningTimer()
    startTicker()
  }

  func togglePause() {
    guard isRunning || isPaused else { return }
    if isRunning {
      updateRemaining()
      isRunning = false
      isPaused = true
      timer?.invalidate()
      persistPausedTimer()
    } else {
      isRunning = true
      isPaused = false
      targetDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
      clearPausedTimer()
      persistRunningTimer()
      startTicker()
    }
  }

  func stop() {
    timer?.invalidate()
    isRunning = false
    isPaused = false
    remainingSeconds = totalSeconds
    targetDate = nil
    clearPersistedTimer()
  }

  private func startTicker() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.updateRemaining() }
    }
  }

  private func updateRemaining() {
    guard let targetDate else { return }
    remainingSeconds = max(0, Int(ceil(targetDate.timeIntervalSinceNow)))
    if remainingSeconds == 0 {
      timer?.invalidate()
      isRunning = false
      isPaused = false
      self.targetDate = nil
      clearPersistedTimer()
      NSSound(named: "Glass")?.play()
    }
  }

  private func restorePersistedTimer() {
    let defaults = UserDefaults.standard
    guard let storedTotal = defaults.object(forKey: StorageKey.totalSeconds) as? Int else { return }

    totalSeconds = storedTotal
    if let pausedSeconds = defaults.object(forKey: StorageKey.pausedSeconds) as? Int {
      remainingSeconds = pausedSeconds
      isPaused = true
      return
    }

    guard let storedTargetDate = defaults.object(forKey: StorageKey.targetDate) as? Date else {
      return
    }
    let seconds = max(0, Int(ceil(storedTargetDate.timeIntervalSinceNow)))
    guard seconds > 0 else {
      clearPersistedTimer()
      return
    }
    remainingSeconds = seconds
    targetDate = storedTargetDate
    isRunning = true
    startTicker()
  }

  private func persistRunningTimer() {
    let defaults = UserDefaults.standard
    defaults.set(totalSeconds, forKey: StorageKey.totalSeconds)
    defaults.set(targetDate, forKey: StorageKey.targetDate)
  }

  private func persistPausedTimer() {
    let defaults = UserDefaults.standard
    defaults.set(totalSeconds, forKey: StorageKey.totalSeconds)
    defaults.set(remainingSeconds, forKey: StorageKey.pausedSeconds)
    defaults.removeObject(forKey: StorageKey.targetDate)
  }

  private func clearPausedTimer() {
    UserDefaults.standard.removeObject(forKey: StorageKey.pausedSeconds)
  }

  private func clearPersistedTimer() {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: StorageKey.totalSeconds)
    defaults.removeObject(forKey: StorageKey.targetDate)
    defaults.removeObject(forKey: StorageKey.pausedSeconds)
  }
}
