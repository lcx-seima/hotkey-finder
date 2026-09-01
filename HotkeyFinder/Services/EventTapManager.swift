@preconcurrency import CoreGraphics
import Foundation

@MainActor
final class EventTapManager {
    var onEvent: ((CapturedHotkeyEvent) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var isRunning: Bool {
        guard let eventTap else { return false }
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    @discardableResult
    func start() -> Bool {
        if isRunning {
            return true
        }

        stop()

        let keyDownMask = CGEventMask(1) << CGEventType.keyDown.rawValue
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: keyDownMask,
            callback: eventTapCallback,
            userInfo: userInfo
        ) else {
            return false
        }

        guard let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        ) else {
            CFMachPortInvalidate(eventTap)
            return false
        }

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource

        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        guard event.getIntegerValueField(.keyboardEventAutorepeat) == 0 else {
            return Unmanaged.passUnretained(event)
        }

        let rawKeyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard rawKeyCode >= 0, rawKeyCode <= Int64(CGKeyCode.max) else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(rawKeyCode)
        let flags = event.flags

        guard ShortcutFormatter.isEligible(keyCode: keyCode, flags: flags) else {
            return Unmanaged.passUnretained(event)
        }

        let rawTargetPID = event.getIntegerValueField(.eventTargetUnixProcessID)
        let targetPID: pid_t
        if rawTargetPID > 0, rawTargetPID <= Int64(Int32.max) {
            targetPID = pid_t(rawTargetPID)
        } else {
            targetPID = 0
        }

        onEvent?(
            CapturedHotkeyEvent(
                keyCode: keyCode,
                flags: flags,
                targetPID: targetPID,
                shortcut: ShortcutFormatter.string(keyCode: keyCode, flags: flags),
                detectedAt: Date()
            )
        )

        return Unmanaged.passUnretained(event)
    }
}

private let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()
    return MainActor.assumeIsolated {
        manager.handle(type: type, event: event)
    }
}
