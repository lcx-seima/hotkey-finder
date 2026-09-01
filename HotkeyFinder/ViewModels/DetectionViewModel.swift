import AppKit
import Combine
import Foundation

@MainActor
final class DetectionViewModel: ObservableObject {
    @Published private(set) var state: DetectionState = .checkingPermission
    @Published private(set) var hasInputMonitoringPermission = false
    @Published private(set) var records: [DetectionRecord] = []

    var latestRecord: DetectionRecord? {
        records.first
    }

    private let eventTapManager = EventTapManager()
    private let processResolver = ProcessResolver()
    private var isApplicationActive = false
    private var pendingEvent: CapturedHotkeyEvent?
    private var pendingResolutionTask: Task<Void, Never>?
    private var delayedStopTask: Task<Void, Never>?
    private var recentActivation: (pid: pid_t, activatedAt: Date)?

    private let activationCorrelationWindow: TimeInterval = 1.5
    private let fallbackDelayNanoseconds: UInt64 = 800_000_000
    private let resignGraceDelayNanoseconds: UInt64 = 350_000_000

    init() {
        eventTapManager.onEvent = { [weak self] event in
            self?.record(event)
        }
    }

    func applicationDidBecomeActive() {
        delayedStopTask?.cancel()
        delayedStopTask = nil
        isApplicationActive = true
        refreshPermissionAndStartIfPossible()
    }

    func applicationDidResignActive() {
        isApplicationActive = false
        state = hasInputMonitoringPermission ? .paused : .permissionRequired

        delayedStopTask?.cancel()
        delayedStopTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: self?.resignGraceDelayNanoseconds ?? 0)
            } catch {
                return
            }

            guard let self, !self.isApplicationActive else {
                return
            }
            self.eventTapManager.stop()
            self.delayedStopTask = nil
        }
    }

    func requestInputMonitoringPermission() {
        state = .checkingPermission
        PermissionManager.requestInputMonitoringPermission()
        refreshPermissionAndStartIfPossible()
    }

    func openInputMonitoringSettings() {
        PermissionManager.openInputMonitoringSettings()
    }

    func retryDetection() {
        refreshPermissionAndStartIfPossible()
    }

    func clearHistory() {
        pendingResolutionTask?.cancel()
        pendingResolutionTask = nil
        pendingEvent = nil
        records.removeAll()
    }

    func workspaceDidActivate(_ application: NSRunningApplication) {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        guard application.processIdentifier != currentPID else {
            recentActivation = nil
            return
        }

        let activatedAt = Date()
        recentActivation = (application.processIdentifier, activatedAt)

        guard let pendingEvent,
              activatedAt.timeIntervalSince(pendingEvent.detectedAt) <= activationCorrelationWindow else {
            return
        }

        resolvePendingEvent(with: application.processIdentifier)
    }

    private func refreshPermissionAndStartIfPossible() {
        hasInputMonitoringPermission = PermissionManager.hasInputMonitoringPermission

        guard hasInputMonitoringPermission else {
            eventTapManager.stop()
            state = .permissionRequired
            return
        }

        guard isApplicationActive else {
            eventTapManager.stop()
            state = .paused
            return
        }

        if eventTapManager.start() {
            state = .detecting
        } else {
            state = .failed("无法创建键盘事件监听。请确认输入监控权限已开启，然后重试或重新启动应用。")
        }
    }

    private func record(_ event: CapturedHotkeyEvent) {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        if event.targetPID > 0,
           event.targetPID != currentPID,
           let application = processResolver.resolve(pid: event.targetPID) {
            appendRecord(for: event, outcome: .application(application))
            return
        }

        if let recentActivation,
           abs(event.detectedAt.timeIntervalSince(recentActivation.activatedAt))
            <= activationCorrelationWindow {
            self.recentActivation = nil
            appendRecord(
                for: event,
                outcome: resolvedOutcome(for: recentActivation.pid)
            )
            return
        }

        resolvePendingAsNoExternalTarget()
        pendingEvent = event
        let eventID = event.id

        pendingResolutionTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: self?.fallbackDelayNanoseconds ?? 0)
            } catch {
                return
            }

            guard self?.pendingEvent?.id == eventID else {
                return
            }
            self?.resolvePendingAsNoExternalTarget()
        }
    }

    private func resolvePendingAsNoExternalTarget() {
        pendingResolutionTask?.cancel()
        pendingResolutionTask = nil

        guard let pendingEvent else {
            return
        }

        self.pendingEvent = nil
        appendRecord(for: pendingEvent, outcome: .noExternalTarget)
    }

    private func resolvePendingEvent(with pid: pid_t) {
        pendingResolutionTask?.cancel()
        pendingResolutionTask = nil

        guard let pendingEvent else {
            return
        }

        self.pendingEvent = nil
        recentActivation = nil
        appendRecord(for: pendingEvent, outcome: resolvedOutcome(for: pid))
    }

    private func resolvedOutcome(for pid: pid_t) -> DetectionOutcome {
        if let application = processResolver.resolve(pid: pid) {
            return .application(application)
        }
        return .unknownTarget(pid)
    }

    private func appendRecord(for event: CapturedHotkeyEvent, outcome: DetectionOutcome) {
        records.insert(
            DetectionRecord(
                detectedAt: event.detectedAt,
                shortcut: event.shortcut,
                keyCode: event.keyCode,
                outcome: outcome
            ),
            at: 0
        )

        if records.count > 20 {
            records.removeLast(records.count - 20)
        }
    }
}
