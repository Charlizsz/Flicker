import AppKit

/// Compile with the app sources except FlickerApp.swift; run in a GUI session.
@main
struct WindowLifecycleChecks {
    @MainActor static func main() {
        let app = NSApplication.shared
        // Volatile arguments domain: no preference files or login items changed.
        UserDefaults.standard.setVolatileDomain([
            "showMenuBarIcon": false, "showInDock": false, "autoCheckUpdates": false
        ], forName: UserDefaults.argumentDomain)
        let delegate = AppDelegate()
        app.delegate = delegate
        // Exercise the real launch delegate without relying on Launch Services
        // metadata for this standalone command-line test executable.
        delegate.applicationWillFinishLaunching(Notification(name: NSApplication.willFinishLaunchingNotification))
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        precondition(app.windows.isEmpty, "Startup must not create a window")
        let input = NSPasteboard.withUniqueName()
        let output = NSPasteboard.withUniqueName()
        defer { input.releaseGlobally(); output.releaseGlobally() }
        input.writeObjects([NSURL(fileURLWithPath: "/tmp/project/outputs/test.txt")])
        let service = PathServices(output: output, projectRoots: { ["/tmp/project"] })
        for mode in ["absolute", "relative", "name"] {
            var error: NSString?
            service.copyPath(input, userData: mode, error: &error)
            precondition(error == nil)
            precondition(app.windows.isEmpty, "Services must not create a window")
        }
        service.copyProjectURLs([URL(fileURLWithPath: "/tmp/project/outputs/test.txt")])
        precondition(output.string(forType: .string) == "outputs/test.txt")
        precondition(app.windows.isEmpty, "Project path copying must not create a window")
        precondition(AppActions.shared.openMainWindow != nil, "UI must be reachable without onAppear")
        precondition(app.windows.isEmpty, "Accessing UI actions must not create a window")
        print("PASS: startup and all copy actions create zero windows; UI action is available")
    }
}
