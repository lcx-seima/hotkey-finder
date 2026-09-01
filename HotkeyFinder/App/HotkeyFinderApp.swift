import SwiftUI

@main
struct HotkeyFinderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = DetectionViewModel()

    var body: some Scene {
        Window("Hotkey Finder", id: "main") {
            ContentView(viewModel: viewModel)
                .onAppear {
                    appDelegate.viewModel = viewModel
                    viewModel.applicationDidBecomeActive()
                }
        }
        .defaultSize(width: 720, height: 600)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

