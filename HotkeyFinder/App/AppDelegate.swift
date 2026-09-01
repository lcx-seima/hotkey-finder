import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var viewModel: DetectionViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        viewModel?.applicationDidBecomeActive()
    }

    func applicationDidResignActive(_ notification: Notification) {
        viewModel?.applicationDidResignActive()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc
    private func workspaceDidActivate(_ notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication else {
            return
        }

        viewModel?.workspaceDidActivate(application)
    }
}
