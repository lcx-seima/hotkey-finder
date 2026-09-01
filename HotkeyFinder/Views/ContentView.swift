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
                    } else if case let .failed(message) = viewModel.state {
                        FailureCard(message: message, viewModel: viewModel)
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
                Text("保持窗口在前台，然后按下要检查的快捷键")
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
                Text("最近活动")
                    .font(.headline)
                Text("\(viewModel.records.count)/20")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                Button("清空记录") {
                    viewModel.clearHistory()
                }
                .disabled(viewModel.records.isEmpty)
            }

            if viewModel.records.isEmpty {
                Text("侦测结果会按时间倒序显示在这里。")
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
            "检查权限"
        case .permissionRequired:
            "需要权限"
        case .detecting:
            "正在侦测"
        case .paused:
            "已暂停"
        case .failed:
            "侦测异常"
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
                Text("需要输入监控权限")
                    .font(.headline)
                Text("Hotkey Finder 仅在窗口位于前台时读取快捷键事件，用来判断事件被路由到了哪个 App。它不会修改或拦截按键。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button("授予输入监控权限") {
                        viewModel.requestInputMonitoringPermission()
                    }
                    .keyboardShortcut(.defaultAction)

                    Button("打开系统设置") {
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
                Text("无法启动侦测")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("重试") {
                        viewModel.retryDetection()
                    }
                    Button("打开系统设置") {
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
            Text("当前结果")
                .font(.headline)

            if let record {
                HStack(spacing: 18) {
                    ResultIcon(outcome: record.outcome, size: 58)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.shortcut)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospaced()
                        OutcomeDetails(outcome: record.outcome, prominent: true)
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
                        Text("等待快捷键")
                            .font(.title3.weight(.semibold))
                        Text("支持带修饰键的组合键以及 F1–F20。")
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

            Text(record.detectedAt, style: .time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
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
                Text("未检测到外部响应 App")
                    .font(prominent ? .title3.weight(.semibold) : .body)
                    .lineLimit(1)
                if prominent {
                    Text("该事件仍然指向 Hotkey Finder。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case let .unknownTarget(pid):
                Text("无法解析目标进程")
                    .font(prominent ? .title3.weight(.semibold) : .body)
                    .lineLimit(1)
                Text(pid > 0 ? "PID \(pid)" : "系统没有提供有效的目标 PID")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func metadata(for application: DetectedApplication) -> String {
        let identifier = application.bundleIdentifier ?? "无 Bundle ID"
        return "\(identifier)  ·  PID \(application.pid)"
    }
}
