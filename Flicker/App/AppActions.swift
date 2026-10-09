import AppKit
import SwiftUI

@MainActor
final class AppActions {
    static let shared = AppActions()
    private var mainWindow: NSWindow?
    private var checkedForUpdates = false
    private init() {}

    // Preserve the call sites used by the menu bar and settings panel. These
    // actions are available even before any view has appeared.
    var openMainWindow: (() -> Void)? { { self.showMainWindow() } }
    var openSettings: (() -> Void)? { { self.showMainWindow() } }

    private func showMainWindow() {
        AppDelegate.prepareForUserInterface()
        if mainWindow == nil {
            let content = ContentView()
                .environmentObject(AppEntryStore())
                .frame(minWidth: 560, minHeight: 420)
            let window = NSWindow(contentViewController: NSHostingController(rootView: content))
            window.title = "Flicker"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 720, height: 520))
            window.minSize = NSSize(width: 560, height: 420)
            window.isReleasedWhenClosed = false
            window.isRestorable = false
            window.center()
            mainWindow = window
        }
        guard let window = mainWindow else { return }
        AppSettings.shared.configureWindowManagementVisibility(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if !checkedForUpdates {
            checkedForUpdates = true
            UpdateChecker.checkAndNotify()
        }
    }
}
