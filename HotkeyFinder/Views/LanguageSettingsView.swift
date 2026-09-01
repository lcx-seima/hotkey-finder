import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject var languageManager: LanguageManager
    @State private var showRestartPrompt = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Language")
                    .font(.headline)
                Text("Choose the language Hotkey Finder uses.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Picker("Language", selection: selectionBinding) {
                ForEach(AppLanguage.allCases) { language in
                    Text(verbatim: language.displayName)
                        .tag(language)
                }
            }
            .labelsHidden()
            .frame(width: 210, alignment: .leading)

            if languageManager.selection == .system {
                HStack(spacing: 4) {
                    Text("System match:")
                    Text(verbatim: languageManager.systemMatchedLanguage.displayName)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if languageManager.needsRelaunch {
                Label("Restart required to apply this change.", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(24)
        .frame(width: 440, height: 210, alignment: .topLeading)
        .alert("Restart Hotkey Finder?", isPresented: $showRestartPrompt) {
            Button("Later", role: .cancel) {}
            Button("Restart Now") {
                languageManager.relaunch()
            }
        } message: {
            Text("The language change will take effect after Hotkey Finder restarts.")
        }
        .alert("Couldn’t Restart", isPresented: relaunchErrorBinding) {
            Button("OK", role: .cancel) {
                languageManager.dismissRelaunchError()
            }
        } message: {
            Text("Hotkey Finder couldn’t restart automatically. Quit and reopen the app to apply the language change.")
        }
    }

    private var selectionBinding: Binding<AppLanguage> {
        Binding(
            get: { languageManager.selection },
            set: { newSelection in
                if languageManager.updateSelection(newSelection),
                   languageManager.needsRelaunch {
                    showRestartPrompt = true
                }
            }
        )
    }

    private var relaunchErrorBinding: Binding<Bool> {
        Binding(
            get: { languageManager.relaunchFailed },
            set: { isPresented in
                if !isPresented {
                    languageManager.dismissRelaunchError()
                }
            }
        )
    }
}
