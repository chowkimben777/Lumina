import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class MediaNowPlayingModel: NSObject {
  private static let qqMusicBundleIdentifier = "com.tencent.QQMusicMac"
  private(set) var title: String?
  private(set) var artist: String?
  private(set) var isPlaying = false
  private(set) var source: String?
  private(set) var isChangingPlayback = false
  private var refreshTask: Task<Void, Never>?
  private var isRefreshing = false

  override init() {
    super.init()
    let center = DistributedNotificationCenter.default()
    center.addObserver(
      self,
      selector: #selector(receiveMusic(_:)),
      name: NSNotification.Name("com.apple.iTunes.playerInfo"),
      object: nil
    )
    center.addObserver(
      self,
      selector: #selector(receiveSpotify(_:)),
      name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
      object: nil
    )
    refreshTask = Task { [weak self] in
      while !Task.isCancelled {
        await self?.refreshSystemNowPlaying()
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }

  @objc private func receiveMusic(_ notification: Notification) {
    update(from: notification.userInfo, source: "Music")
  }

  @objc private func receiveSpotify(_ notification: Notification) {
    update(from: notification.userInfo, source: "Spotify")
  }

  private func update(from info: [AnyHashable: Any]?, source: String) {
    title = info?["Name"] as? String ?? info?["Track Name"] as? String
    artist = info?["Artist"] as? String
    let state = info?["Player State"] as? String ?? info?["Playback Status"] as? String
    isPlaying = state?.lowercased() == "playing"
    self.source = source
  }

  func togglePlayback() {
    guard let source else { return }
    if source == "QQ 音乐" {
      guard !isChangingPlayback else { return }
      isChangingPlayback = true
      isPlaying.toggle()
      Task {
        _ = await runMediaBridge(arguments: ["toggle"])
        try? await Task.sleep(for: .milliseconds(250))
        isChangingPlayback = false
        await refreshSystemNowPlaying(force: true)
      }
      return
    }
    let target = source == "Spotify" ? "Spotify" : "Music"
    let script = "tell application \"\(target)\" to playpause"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    try? process.run()
  }

  private func refreshSystemNowPlaying(force: Bool = false) async {
    guard !isRefreshing, force || !isChangingPlayback else { return }
    isRefreshing = true
    defer { isRefreshing = false }

    guard
      !NSRunningApplication.runningApplications(
        withBundleIdentifier: Self.qqMusicBundleIdentifier
      ).isEmpty
    else {
      clearQQMusicIfNeeded()
      return
    }

    guard let data = await runMediaBridge(arguments: []) else { return }
    guard let payload = try? JSONDecoder().decode(MediaBridgePayload.self, from: data) else {
      clearQQMusicIfNeeded()
      return
    }

    guard payload.bundleIdentifier == Self.qqMusicBundleIdentifier,
      let title = payload.title,
      !title.isEmpty
    else {
      clearQQMusicIfNeeded()
      return
    }

    self.title = title
    artist = payload.artist
    isPlaying = payload.playing ?? false
    source = "QQ 音乐"
  }

  private func clearQQMusicIfNeeded() {
    guard source == "QQ 音乐" else { return }
    title = nil
    artist = nil
    isPlaying = false
    source = nil
  }

  private func runMediaBridge(arguments: [String]) async -> Data? {
    guard let scriptURL = Bundle.main.url(forResource: "MediaBridge", withExtension: "pl"),
      let libraryURL = Bundle.main.url(forResource: "MediaRemoteAdapter", withExtension: "dylib")
    else {
      return nil
    }

    return await Task.detached(priority: .utility) {
      let process = Process()
      let output = Pipe()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
      process.arguments = [scriptURL.path, libraryURL.path] + arguments
      process.standardOutput = output
      process.standardError = FileHandle.nullDevice
      do {
        try process.run()
      } catch {
        return nil
      }
      let data = output.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      return process.terminationStatus == 0 ? data : nil
    }.value
  }
}

private struct MediaBridgePayload: Decodable {
  let bundleIdentifier: String?
  let title: String?
  let artist: String?
  let playing: Bool?
}
