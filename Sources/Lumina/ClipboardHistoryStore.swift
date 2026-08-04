import AppKit
import Foundation
import Observation

struct ClipboardEntry: Identifiable, Codable, Equatable {
  enum Kind: String, Codable {
    case text
    case image
  }

  let id: UUID
  var kind: Kind
  var text: String?
  var imageData: Data?
  var createdAt: Date
  var isPinned: Bool

  var displayText: String {
    guard let text, !text.isEmpty else { return "图片" }
    return text.replacingOccurrences(of: "\n", with: " ")
  }
}

@MainActor
@Observable
final class ClipboardHistoryStore {
  private(set) var entries: [ClipboardEntry] = []
  private var timer: Timer?
  private var lastChangeCount = NSPasteboard.general.changeCount
  private let maximumEntries = 50
  private let concealedPasteboardTypes = [
    "org.nspasteboard.ConcealedType",
    "com.agilebits.onepassword",
    "org.keepassxc.keepassxc",
  ]

  init() {
    load()
    timer = Timer.scheduledTimer(withTimeInterval: 0.65, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.captureIfNeeded() }
    }
  }

  func restore(_ entry: ClipboardEntry) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    switch entry.kind {
    case .text:
      if let text = entry.text {
        pasteboard.setString(text, forType: .string)
      }
    case .image:
      if let data = entry.imageData {
        pasteboard.setData(data, forType: .tiff)
      }
    }
    lastChangeCount = pasteboard.changeCount
  }

  func togglePinned(_ entry: ClipboardEntry) {
    guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
    entries[index].isPinned.toggle()
    sortEntries()
    save()
  }

  func delete(_ entry: ClipboardEntry) {
    entries.removeAll { $0.id == entry.id }
    save()
  }

  func clearUnpinned() {
    entries.removeAll { !$0.isPinned }
    save()
  }

  private func captureIfNeeded() {
    let pasteboard = NSPasteboard.general
    guard pasteboard.changeCount != lastChangeCount else { return }
    lastChangeCount = pasteboard.changeCount

    let currentTypes = Set((pasteboard.types ?? []).map(\.rawValue))
    guard concealedPasteboardTypes.allSatisfy({ !currentTypes.contains($0) }) else { return }

    if let text = pasteboard.string(forType: .string),
      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      add(
        ClipboardEntry(
          id: UUID(), kind: .text, text: text, imageData: nil, createdAt: .now, isPinned: false))
    } else if let data = pasteboard.data(forType: .tiff), data.count <= 5_000_000 {
      add(
        ClipboardEntry(
          id: UUID(), kind: .image, text: nil, imageData: data, createdAt: .now, isPinned: false))
    }
  }

  private func add(_ entry: ClipboardEntry) {
    entries.removeAll { existing in
      existing.kind == entry.kind && existing.text == entry.text
        && existing.imageData == entry.imageData
    }
    entries.insert(entry, at: 0)
    let pinned = entries.filter(\.isPinned)
    let recent = entries.filter { !$0.isPinned }.prefix(max(0, maximumEntries - pinned.count))
    entries = pinned + recent
    sortEntries()
    save()
  }

  private func sortEntries() {
    entries.sort {
      if $0.isPinned != $1.isPinned { return $0.isPinned }
      return $0.createdAt > $1.createdAt
    }
  }

  private var storageURL: URL? {
    guard
      let directory = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
      ).first
    else { return nil }
    let appDirectory = directory.appendingPathComponent("Lumina", isDirectory: true)
    try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
    return appDirectory.appendingPathComponent("clipboard-history.json")
  }

  private func load() {
    guard let url = storageURL,
      let data = try? Data(contentsOf: url),
      let decoded = try? JSONDecoder().decode([ClipboardEntry].self, from: data)
    else { return }
    entries = decoded
    sortEntries()
  }

  private func save() {
    guard let url = storageURL, let data = try? JSONEncoder().encode(entries) else { return }
    try? data.write(to: url, options: .atomic)
  }
}
