import AppKit
import CoreGraphics
import Foundation

enum PermissionManager {
    static var hasInputMonitoringPermission: Bool {
        CGPreflightListenEventAccess()
    }

    @discardableResult
    static func requestInputMonitoringPermission() -> Bool {
        CGRequestListenEventAccess()
    }

    static func openInputMonitoringSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    static var hasScreenCapturePermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    static func requestScreenCapturePermission() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    static func openScreenCaptureSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
