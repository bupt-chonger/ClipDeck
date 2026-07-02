import AppKit

enum ActiveScreenResolver {
    static func screenForMouse() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main ?? NSScreen.screens.first!
    }
}
