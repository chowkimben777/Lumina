import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class MediaNowPlayingModel: NSObject {
  private(set) var title: String?
  private(set) var artist: String?
  private(set) var isPlaying = false
  private(set) var source: String?

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
    let target = source == "Spotify" ? "Spotify" : "Music"
    let script = "tell application \"\(target)\" to playpause"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    try? process.run()
  }
}
