import AppKit

@main
struct DefineApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // Menu bar app: no Dock icon, no app switcher entry. The bundled app
        // also sets LSUIElement, but this keeps `swift run` behaving the same.
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
