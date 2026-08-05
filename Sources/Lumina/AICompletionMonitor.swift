import AppKit
import Foundation

@MainActor
final class AICompletionMonitor {
  var onCompletion: ((AICompletionSource) -> Void)?

  private let fileManager: FileManager
  private let codexSessionsURL: URL
  private let traeSnapshotsURL: URL
  private var pollingTask: Task<Void, Never>?
  private var codexSessionURL: URL?
  private var codexSessionOffset: UInt64 = 0
  private var codexTaskUsedTools = false
  private var lastCodexSessionDiscovery = Date.distantPast
  private var knownTraeCompletionTags: Set<String> = []
  private var lastTraeTagDiscovery = Date.distantPast

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
    let home = fileManager.homeDirectoryForCurrentUser
    codexSessionsURL = home.appending(path: ".codex/sessions")
    traeSnapshotsURL = home.appending(
      path: "Library/Application Support/Trae CN/ModularData/ai-agent/snapshot"
    )
  }

  deinit {
    pollingTask?.cancel()
  }

  func start() {
    guard pollingTask == nil else { return }
    knownTraeCompletionTags = traeCompletionTags()
    pollingTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(750))
        guard !Task.isCancelled else { return }
        self?.poll()
      }
    }
  }

  private func poll() {
    pollCodexSession()
    pollTraeCompletionTags()
  }

  private func pollCodexSession() {
    refreshCodexSessionIfNeeded()
    guard let codexSessionURL,
      let attributes = try? fileManager.attributesOfItem(atPath: codexSessionURL.path),
      let fileSize = attributes[.size] as? NSNumber
    else { return }

    let size = fileSize.uint64Value
    guard size > codexSessionOffset else {
      if size < codexSessionOffset {
        codexSessionOffset = size
      }
      return
    }

    guard let handle = try? FileHandle(forReadingFrom: codexSessionURL) else { return }
    defer { try? handle.close() }
    do {
      try handle.seek(toOffset: codexSessionOffset)
      guard let data = try handle.readToEnd() else { return }
      codexSessionOffset += UInt64(data.count)
      processCodexLog(data)
    } catch {
      return
    }
  }

  private func refreshCodexSessionIfNeeded() {
    let now = Date()
    guard now.timeIntervalSince(lastCodexSessionDiscovery) >= 2 else { return }
    lastCodexSessionDiscovery = now
    guard let latestSessionURL = mostRecentCodexSessionURL(), latestSessionURL != codexSessionURL
    else { return }

    codexSessionURL = latestSessionURL
    let attributes = try? fileManager.attributesOfItem(atPath: latestSessionURL.path)
    codexSessionOffset = (attributes?[.size] as? NSNumber)?.uint64Value ?? 0
    codexTaskUsedTools = false
  }

  private func mostRecentCodexSessionURL() -> URL? {
    guard
      let enumerator = fileManager.enumerator(
        at: codexSessionsURL,
        includingPropertiesForKeys: [.contentModificationDateKey],
        options: [.skipsHiddenFiles]
      )
    else { return nil }

    var newest: (url: URL, modificationDate: Date)?
    for case let url as URL in enumerator where url.pathExtension == "jsonl" {
      guard
        let modificationDate = try? url.resourceValues(forKeys: [.contentModificationDateKey])
          .contentModificationDate
      else { continue }
      if newest == nil || modificationDate > newest!.modificationDate {
        newest = (url, modificationDate)
      }
    }
    return newest?.url
  }

  private func processCodexLog(_ data: Data) {
    for line in data.split(separator: 0x0A) {
      guard let object = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any],
        object["type"] as? String == "event_msg",
        let payload = object["payload"] as? [String: Any],
        let eventType = payload["type"] as? String
      else { continue }

      switch eventType {
      case "task_started":
        codexTaskUsedTools = false
      case "mcp_tool_call_end", "patch_apply_end":
        codexTaskUsedTools = true
      case "task_complete":
        let duration = payload["duration_ms"] as? Int ?? 0
        if codexTaskUsedTools || duration >= 8_000 {
          notifyIfNeeded(for: .codex)
        }
        codexTaskUsedTools = false
      default:
        break
      }
    }
  }

  private func pollTraeCompletionTags() {
    guard
      NSWorkspace.shared.runningApplications.contains(where: {
        $0.bundleIdentifier == "cn.trae.app"
      })
    else { return }

    let now = Date()
    guard now.timeIntervalSince(lastTraeTagDiscovery) >= 1.5 else { return }
    lastTraeTagDiscovery = now

    let currentTags = traeCompletionTags()
    let completedTags = currentTags.subtracting(knownTraeCompletionTags)
    knownTraeCompletionTags = currentTags
    guard !completedTags.isEmpty else { return }
    notifyIfNeeded(for: .trae)
  }

  private func notifyIfNeeded(for source: AICompletionSource) {
    guard !isAIApplicationFrontmost else { return }
    onCompletion?(source)
  }

  private var isAIApplicationFrontmost: Bool {
    guard let application = NSWorkspace.shared.frontmostApplication else { return false }
    let bundleIdentifier = application.bundleIdentifier?.lowercased() ?? ""
    let applicationName = application.localizedName?.lowercased() ?? ""
    return bundleIdentifier == "cn.trae.app"
      || bundleIdentifier.contains("codex")
      || applicationName == "codex"
      || applicationName.contains("trae")
  }

  private func traeCompletionTags() -> Set<String> {
    var tags: Set<String> = []
    guard
      let snapshots = try? fileManager.contentsOfDirectory(
        at: traeSnapshotsURL,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )
    else { return tags }

    for snapshot in snapshots {
      let tagsURL = snapshot.appending(path: "v2/.git/refs/tags")
      guard
        let tagURLs = try? fileManager.contentsOfDirectory(
          at: tagsURL,
          includingPropertiesForKeys: nil,
          options: [.skipsHiddenFiles]
        )
      else { continue }
      for tagURL in tagURLs where tagURL.lastPathComponent.hasPrefix("after-chat-turn-") {
        tags.insert(tagURL.path)
      }
    }
    return tags
  }

}
