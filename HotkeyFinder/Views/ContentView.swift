import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: DetectionViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.hasInputMonitoringPermission {
                        PermissionCard(viewModel: viewModel)
                    } else {
                        if case let .failed(message) = viewModel.state {
                            FailureCard(message: message, viewModel: viewModel)
                        }

                        if !viewModel.hasScreenCapturePermission {
                            ScreenCapturePermissionCard(viewModel: viewModel)
                        }
                    }

                    LatestResultCard(record: viewModel.latestRecord)
                    history
                }
                .padding(24)
            }
        }
        .frame(minWidth: 600, minHeight: 480)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "command.square.fill")
                .font(.system(size: 30))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Hotkey Finder")
                    .font(.title2.weight(.semibold))
                Text("Keep this window in front, then press the shortcut you want to inspect.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(state: viewModel.state)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Text(verbatim: "\(viewModel.records.count)/20")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear History") {
                    viewModel.clearHistory()
                }
                .disabled(viewModel.records.isEmpty)
            }

            if viewModel.records.isEmpty {
                Text("Detection results appear here, newest first.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.records.enumerated()), id: \.element.id) { index, record in
                        HistoryRow(record: record)
                        if index < viewModel.records.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.separator.opacity(0.45), lineWidth: 1)
                }
            }
        }
    }
}

private struct ScreenCapturePermissionCard: View {
    @ObservedObject var viewModel: DetectionViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "macwindow.on.rectangle")
                .font(.system(size: 27))
                .foregroundStyle(Color.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("Enable Window Detection (Optional)")
                    .font(.headline)
                Text("Helps identify apps like Alfred that do not become active. Hotkey Finder only compares window metadata such as identifiers, owning processes, and sizes. It never captures or saves your screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button("Allow Screen Recording") {
                        viewModel.requestScreenCapturePermission()
                    }

                    Button("Open System Settings") {
                        viewModel.openScreenCaptureSettings()
                    }
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color.accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        }
    }
}

private struct StatusBadge: View {
    let state: DetectionState

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }

    private var title: String {
        switch state {
        case .checkingPermission:
            String(localized: "Checking Permissions")
        case .permissionRequired:
            String(localized: "Permission Required")
        case .detecting:
            String(localized: "Detecting")
        case .paused:
            String(localized: "Paused")
        case .failed:
            String(localized: "Detection Error")
        }
    }

    private var systemImage: String {
        switch state {
        case .checkingPermission:
            "arrow.trianglehead.2.clockwise.rotate.90"
        case .permissionRequired:
            "exclamationmark.shield"
        case .detecting:
            "waveform"
        case .paused:
            "pause.fill"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }

    private var tint: Color {
        switch state {
        case .checkingPermission:
            .secondary
        case .permissionRequired:
            .orange
        case .detecting:
            .green
        case .paused:
            .secondary
        case .failed:
            .red
        }
    }
}

private struct PermissionCard: View {
    @ObservedObject var viewModel: DetectionViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 28))
                .foregroundStyle(.orange)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("Input Monitoring Access Required")
                    .font(.headline)
                Text("Hotkey Finder reads keyboard events only while its window is in front so it can identify which app receives a shortcut. It never changes or blocks your keystrokes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button("Allow Input Monitoring") {
                        viewModel.requestInputMonitoringPermission()
                    }
                    .keyboardShortcut(.defaultAction)

                    Button("Open System Settings") {
                        viewModel.openInputMonitoringSettings()
                    }
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.orange.opacity(0.25), lineWidth: 1)
        }
    }
}

private struct FailureCard: View {
    let message: String
    @ObservedObject var viewModel: DetectionViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 26))
                .foregroundStyle(.red)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("Unable to Start Detection")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Try Again") {
                        viewModel.retryDetection()
                    }
                    Button("Open System Settings") {
                        viewModel.openInputMonitoringSettings()
                    }
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.red.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct LatestResultCard: View {
    let record: DetectionRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Result")
                .font(.headline)

            if let record {
                HStack(spacing: 18) {
                    ResultIcon(outcome: record.outcome, size: 58)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.shortcut)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospaced()
                        OutcomeDetails(outcome: record.outcome, prominent: true)
                        if let method = record.method {
                            DetectionMethodBadge(method: method)
                        }
                    }

                    Spacer()

                    Text(record.detectedAt, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 14) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                        .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Waiting for a Shortcut")
                            .font(.title3.weight(.semibold))
                        Text("Shortcuts with modifiers and F1–F20 are supported.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.separator.opacity(0.5), lineWidth: 1)
        }
    }
}

private struct HistoryRow: View {
    let record: DetectionRecord

    var body: some View {
        HStack(spacing: 12) {
            ResultIcon(outcome: record.outcome, size: 36)

            Text(record.shortcut)
                .font(.body.weight(.semibold).monospaced())
                .frame(width: 112, alignment: .leading)
                .lineLimit(1)

            OutcomeDetails(outcome: record.outcome, prominent: false)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                Text(record.detectedAt, style: .time)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                if let method = record.method {
                    DetectionMethodBadge(method: method)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

private struct DetectionMethodBadge: View {
    let method: DetectionMethod

    var body: some View {
        Text(method.displayName)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.quaternary.opacity(0.7), in: Capsule())
    }
}

private struct ResultIcon: View {
    let outcome: DetectionOutcome
    let size: CGFloat

    var body: some View {
        ZStack {
            switch outcome {
            case let .application(application):
                if let icon = application.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "app.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.accentColor)
                }
            case .noExternalTarget:
                Image(systemName: "command.square")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            case .unknownTarget:
                Image(systemName: "questionmark.app")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.orange)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct OutcomeDetails: View {
    let outcome: DetectionOutcome
    let prominent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: prominent ? 3 : 1) {
            switch outcome {
            case let .application(application):
                Text(application.name)
                    .font(prominent ? .title3.weight(.semibold) : .body)
                    .lineLimit(1)

                Text(metadata(for: application))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            case .noExternalTarget:
                Text("No Responding App Detected")
                    .font(prominent ? .title3.weight(.semibold) : .body)
                    .lineLimit(1)
                if prominent {
                    Text("The event is still targeting Hotkey Finder.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case let .unknownTarget(pid):
                Text("Unable to Identify Target Process")
                    .font(prominent ? .title3.weight(.semibold) : .body)
                    .lineLimit(1)
                if pid > 0 {
                    Text(verbatim: "PID \(pid)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("The system did not provide a valid target PID.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func metadata(for application: DetectedApplication) -> String {
        let identifier = application.bundleIdentifier ?? String(localized: "No Bundle ID")
        return "\(identifier)  ·  PID \(application.pid)"
    }
}
