import CoreGraphics
import Foundation

struct ObservedWindow: Sendable {
    let id: CGWindowID
    let ownerPID: pid_t
    let width: Double
    let height: Double
    let alpha: Double
    let order: Int
}

struct WindowSnapshot: Sendable {
    let capturedAt: Date
    let windows: [CGWindowID: ObservedWindow]

    static let empty = WindowSnapshot(capturedAt: .distantPast, windows: [:])

    func bestNewWindowOwner(
        comparedTo baseline: WindowSnapshot,
        excludingPID: pid_t
    ) -> pid_t? {
        windows.values
            .filter { window in
                baseline.windows[window.id] == nil
                    && window.ownerPID > 0
                    && window.ownerPID != excludingPID
                    && window.alpha > 0.01
                    && window.width >= 20
                    && window.height >= 20
                    && window.width * window.height >= 1_600
            }
            .sorted { lhs, rhs in
                if lhs.order != rhs.order {
                    return lhs.order < rhs.order
                }
                return lhs.width * lhs.height > rhs.width * rhs.height
            }
            .first?
            .ownerPID
    }
}

actor WindowObservationService {
    private var latestSnapshot = WindowSnapshot.empty
    private var recentSnapshots: [WindowSnapshot] = []
    private var monitorTask: Task<Void, Never>?
    private let refreshIntervalNanoseconds: UInt64 = 200_000_000

    func startMonitoring() {
        guard monitorTask == nil else {
            return
        }

        store(Self.makeSnapshot())
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: self?.refreshIntervalNanoseconds ?? 0)
                } catch {
                    return
                }

                guard let self, !Task.isCancelled else {
                    return
                }
                await self.refreshSnapshot()
            }
        }
    }

    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
        latestSnapshot = .empty
        recentSnapshots.removeAll()
    }

    func baseline(before date: Date) -> WindowSnapshot {
        recentSnapshots.last { $0.capturedAt <= date } ?? latestSnapshot
    }

    func captureSnapshot() -> WindowSnapshot {
        let snapshot = Self.makeSnapshot()
        store(snapshot)
        return snapshot
    }

    private func refreshSnapshot() {
        store(Self.makeSnapshot())
    }

    private func store(_ snapshot: WindowSnapshot) {
        latestSnapshot = snapshot
        recentSnapshots.append(snapshot)
        if recentSnapshots.count > 12 {
            recentSnapshots.removeFirst(recentSnapshots.count - 12)
        }
    }

    private nonisolated static func makeSnapshot() -> WindowSnapshot {
        guard let windowInfo = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[CFString: Any]] else {
            return WindowSnapshot(capturedAt: Date(), windows: [:])
        }

        var windows: [CGWindowID: ObservedWindow] = [:]
        for (order, info) in windowInfo.enumerated() {
            guard let windowNumber = info[kCGWindowNumber] as? NSNumber,
                  let ownerPID = info[kCGWindowOwnerPID] as? NSNumber,
                  let boundsDictionary = info[kCGWindowBounds] as? [String: Any],
                  let width = boundsDictionary["Width"] as? NSNumber,
                  let height = boundsDictionary["Height"] as? NSNumber else {
                continue
            }

            let id = CGWindowID(windowNumber.uint32Value)
            windows[id] = ObservedWindow(
                id: id,
                ownerPID: pid_t(ownerPID.int32Value),
                width: width.doubleValue,
                height: height.doubleValue,
                alpha: (info[kCGWindowAlpha] as? NSNumber)?.doubleValue ?? 1,
                order: order
            )
        }

        return WindowSnapshot(capturedAt: Date(), windows: windows)
    }
}
