import SwiftUI

@main
struct HotkeyFinderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = DetectionViewModel()
    @StateObject private var languageManager = LanguageManager()

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
            UnusedFileCommands()
            UnusedEditingCommands()
            UnusedWindowCommands()
        }

        Settings {
            LanguageSettingsView(languageManager: languageManager)
        }
    }
}

private struct UnusedFileCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .systemServices) {}
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .saveItem) {}
        CommandGroup(replacing: .importExport) {}
        CommandGroup(replacing: .printItem) {}
    }
}

private struct UnusedEditingCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {}
        CommandGroup(replacing: .pasteboard) {}
        CommandGroup(replacing: .textEditing) {}
        CommandGroup(replacing: .textFormatting) {}
        CommandGroup(replacing: .toolbar) {}
        CommandGroup(replacing: .sidebar) {}
    }
}

private struct UnusedWindowCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .windowArrangement) {}
        CommandGroup(replacing: .windowList) {}
        CommandGroup(replacing: .singleWindowList) {}
        CommandGroup(replacing: .help) {}
    }
}
