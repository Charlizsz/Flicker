//
//  AppDelegate.swift
//  Flicker
//
//  管理 URL 启动检测、窗口复用策略，并按用户设置应用
//  程序坞 / 菜单栏 / 开机自启动。
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// 是否由 URL 或系统服务拉起；主动打开界面时清除。
    /// 仅在主线程读写。
    nonisolated(unsafe) static var launchedInBackground = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        Self.launchedInBackground = true
    }

    private var pathServices: PathServices?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Startup is intentionally windowless, including login, Services and
        // URLs. Dock policy is applied only when the user requests the UI.
        Self.launchedInBackground = true
        NSApp.setActivationPolicy(.accessory)
        AppSettings.shared.applyMenuBar()
        // Register after launch policy is set: a service can arrive immediately.
        let provider = PathServices()
        pathServices = provider
        NSApp.servicesProvider = provider
        NSUpdateDynamicServices()
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 用户再次打开已运行的应用（如从 Dock / Finder 点击）：显示主窗口并应用界面设置。
        showMainWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 后台复制时保持服务进程存活；普通界面沿用原有退出偏好。
        return !Self.launchedInBackground && !AppSettings.shared.showMenuBarIcon
    }

    @MainActor @objc func showMainWindow() {
        AppActions.shared.openMainWindow?()
    }
    
    @MainActor static func prepareForUserInterface() {
        launchedInBackground = false
        AppSettings.shared.applyAll()
    }

    // MARK: - URL Handling
    
    func application(_ application: NSApplication, open urls: [URL]) {
        Log.debug("application open urls: \(urls)")
        for url in urls {
            URLOpener.handle(url)
        }
    }

    func application(_ application: NSApplication, open url: URL) -> Bool {
        Log.debug("application open url: \(url)")
        URLOpener.handle(url)
        return true
    }
}
