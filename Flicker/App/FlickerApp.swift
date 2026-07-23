//
//  FlickerApp.swift
//  Flicker
//
//  Container app entry point.
//

import SwiftUI

@main
struct FlickerApp: App {
    static let mainWindowID = "main"
    @StateObject private var store = AppEntryStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettingsEnv

    var body: some Scene {
        Window("Flicker", id: Self.mainWindowID) {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 560, minHeight: 420)
                .onAppear {
                    // 捕获场景动作到桥接单例；窗口关闭后闭包仍有效。
                    AppActions.shared.openMainWindow = { [self] in
                        openWindow(id: Self.mainWindowID)
                    }
                    AppActions.shared.openSettings = { [self] in
                        openSettingsEnv()
                    }
                }
                .onOpenURL { url in
                    URLOpener.handle(url)
                }
                .background(WindowManagementConfigurator())
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: 720, height: 520)

        Settings {
            SettingsView()
        }
    }
}

private struct WindowManagementConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                AppSettings.shared.configureWindowManagementVisibility(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                AppSettings.shared.configureWindowManagementVisibility(window)
            }
        }
    }
}
