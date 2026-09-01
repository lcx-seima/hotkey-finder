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

        DispatchQueue.main.async {
            self.removeEmptyTopLevelMenus()
        }
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

    private func removeEmptyTopLevelMenus() {
        guard let mainMenu = NSApp.mainMenu else { return }

        for item in mainMenu.items where item.submenu?.items.isEmpty == true {
            mainMenu.removeItem(item)
        }
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
