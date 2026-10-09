import AppKit

/// Services and URL requests must not instantiate a SwiftUI Window scene.
/// The configuration window is created on demand by AppActions.
@main
enum FlickerApp {
    @MainActor static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}
