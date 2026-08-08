import AppKit
import SwiftUI

@main
struct LuminaApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var panelController: IslandPanelController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    panelController = IslandPanelController()
    panelController?.show()
  }
}

@MainActor
final class IslandPanelController {
  private let panel: IslandPanel
  private let model = IslandModel()
  private let containerView: IslandContainerView
  private var currentSize = IslandLayout.compactSize
  private var hoverTimer: Timer?
  private var wasPointerInside = false

  init() {
    panel = IslandPanel(
      contentRect: NSRect(origin: .zero, size: IslandLayout.panelSize),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 1)
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.animationBehavior = .none
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    panel.hidesOnDeactivate = false
    panel.isMovable = false
    containerView = IslandContainerView(
      frame: NSRect(origin: .zero, size: IslandLayout.panelSize)
    )
    containerView.activeIslandSize = currentSize
    containerView.autoresizingMask = [.width, .height]
    let hostingView = FirstMouseHostingView(
      rootView:
        IslandRootView(
          onSizeChange: { [weak self] size in
            self?.updateInteractionSize(to: size)
          },
          onPresentationChange: { [weak self] presentation in
            self?.updateFocusPolicy(for: presentation)
          }
        )
        .environment(model)
        .ignoresSafeArea(edges: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    )
    hostingView.sizingOptions = []
    hostingView.safeAreaRegions = []
    hostingView.frame = NSRect(origin: .zero, size: IslandLayout.panelSize)
    hostingView.autoresizingMask = [.width, .height]
    containerView.addSubview(hostingView)
    panel.contentView = containerView
    position()

    NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.position()
      }
    }

    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.pollPointerPosition() }
    }
  }

  func show() {
    panel.orderFrontRegardless()
  }

  private func updateInteractionSize(to size: CGSize) {
    guard size != currentSize else { return }
    currentSize = size
    containerView.activeIslandSize = size
  }

  private func updateFocusPolicy(for presentation: IslandPresentation) {
    // Automatic status and reminder popups must remain transparent to the
    // foreground app's keyboard handling. Editing a reminder is deliberate.
    if case .module(.reminder) = presentation {
      panel.allowsKeyFocus = true
    } else {
      panel.allowsKeyFocus = false
      panel.makeFirstResponder(nil)
    }
  }

  private func position() {
    guard let screen = IslandLayout.notchScreen else { return }
    let frame = screen.frame
    // Keep the island's rendered top beyond the display edge. The WindowServer
    // clips the overscan, which removes the transparent row it otherwise adds.
    let topEdge = frame.maxY + IslandLayout.topAttachmentOverscan
    let target = NSRect(
      x: frame.midX - IslandLayout.panelSize.width / 2,
      y: topEdge - IslandLayout.panelSize.height,
      width: IslandLayout.panelSize.width,
      height: IslandLayout.panelSize.height
    )
    panel.setFrame(target, display: true)
  }

  private func pollPointerPosition() {
    let interactionFrame = NSRect(
      x: panel.frame.midX - currentSize.width / 2,
      y: panel.frame.maxY - currentSize.height,
      width: currentSize.width,
      height: currentSize.height
    )
    let isPointerInside = interactionFrame.contains(NSEvent.mouseLocation)
    guard isPointerInside != wasPointerInside else { return }
    wasPointerInside = isPointerInside
    model.hoverChanged(isPointerInside)
  }
}

final class IslandPanel: NSPanel {
  var allowsKeyFocus = false

  override var canBecomeKey: Bool { allowsKeyFocus }
  override var canBecomeMain: Bool { false }

  override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
    frameRect
  }
}

final class IslandContainerView: NSView {
  var activeIslandSize = IslandLayout.compactSize

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    let islandFrame = NSRect(
      x: bounds.midX - activeIslandSize.width / 2,
      y: bounds.maxY - activeIslandSize.height,
      width: activeIslandSize.width,
      height: activeIslandSize.height
    )
    guard islandFrame.contains(point) else { return nil }
    return super.hitTest(point)
  }
}

final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }
}
