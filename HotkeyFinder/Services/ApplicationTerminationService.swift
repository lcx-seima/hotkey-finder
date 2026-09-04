import AppKit
import Foundation

enum ApplicationTerminationResult {
    case terminated
    case alreadyTerminated
    case rejected
    case timedOut
}

@MainActor
struct ApplicationTerminationService {
    private let verificationAttempts = 20
    private let verificationDelayNanoseconds: UInt64 = 100_000_000

    func forceTerminate(_ application: DetectedApplication) async -> ApplicationTerminationResult {
        let runningApplication = application.runningApplication

        guard application.pid != ProcessInfo.processInfo.processIdentifier else {
            return .rejected
        }

        guard !runningApplication.isTerminated else {
            return .alreadyTerminated
        }

        guard runningApplication.processIdentifier == application.pid,
              runningApplication.bundleIdentifier == application.instanceID.bundleIdentifier,
              runningApplication.launchDate == application.instanceID.launchDate else {
            return runningApplication.isTerminated ? .alreadyTerminated : .rejected
        }

        guard runningApplication.forceTerminate() else {
            return runningApplication.isTerminated ? .terminated : .rejected
        }

        for _ in 0..<verificationAttempts {
            if runningApplication.isTerminated {
                return .terminated
            }

            do {
                try await Task.sleep(nanoseconds: verificationDelayNanoseconds)
            } catch {
                break
            }
        }

        return runningApplication.isTerminated ? .terminated : .timedOut
    }
}
