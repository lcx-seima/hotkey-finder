import AppKit
import Foundation

@MainActor
struct ProcessResolver {
    func resolve(pid: pid_t) -> DetectedApplication? {
        guard let application = NSRunningApplication(processIdentifier: pid) else {
            return nil
        }

        let fallbackName = application.executableURL?.deletingPathExtension().lastPathComponent
            ?? application.bundleIdentifier
            ?? "PID \(pid)"

        return DetectedApplication(
            pid: pid,
            name: application.localizedName ?? fallbackName,
            bundleIdentifier: application.bundleIdentifier,
            icon: application.icon
        )
    }
}

