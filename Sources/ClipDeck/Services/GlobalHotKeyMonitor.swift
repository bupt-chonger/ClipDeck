import Carbon
import ClipDeckCore
import Foundation

final class GlobalHotKeyMonitor {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    deinit {
        stop()
    }

    func start(shortcut: KeyboardShortcutPreference = .default) {
        stop()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let monitor = Unmanaged<GlobalHotKeyMonitor>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                monitor.callback()
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(signature: OSType("CLIP".fourCharCode), id: 1)
        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}

private extension String {
    var fourCharCode: FourCharCode {
        utf8.reduce(0) { result, byte in
            (result << 8) + FourCharCode(byte)
        }
    }
}
