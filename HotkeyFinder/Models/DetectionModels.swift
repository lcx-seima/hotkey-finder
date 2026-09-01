import AppKit
import CoreGraphics
import Foundation

enum DetectionState: Equatable {
    case checkingPermission
    case permissionRequired
    case detecting
    case paused
    case failed(String)
}

struct CapturedHotkeyEvent: Identifiable, Sendable {
    let id = UUID()
    let keyCode: CGKeyCode
    let flags: CGEventFlags
    let targetPID: pid_t
    let shortcut: String
    let detectedAt: Date
}

struct DetectedApplication: Identifiable {
    let pid: pid_t
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage?

    var id: pid_t { pid }
}

enum DetectionOutcome {
    case application(DetectedApplication)
    case noExternalTarget
    case unknownTarget(pid_t)
}

enum DetectionMethod {
    case eventTarget
    case applicationActivation
    case newWindow

    var displayName: String {
        switch self {
        case .eventTarget:
            "事件目标"
        case .applicationActivation:
            "App 激活"
        case .newWindow:
            "新窗口"
        }
    }
}

struct DetectionRecord: Identifiable {
    let id = UUID()
    let detectedAt: Date
    let shortcut: String
    let keyCode: CGKeyCode
    let outcome: DetectionOutcome
    let method: DetectionMethod?
}
