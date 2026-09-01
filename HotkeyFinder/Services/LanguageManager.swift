import AppKit
import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case thai = "th"

    var id: String { rawValue }

    var localizationCode: String? {
        self == .system ? nil : rawValue
    }

    var displayName: String {
        switch self {
        case .system:
            String(localized: "Follow System")
        case .english:
            "English"
        case .simplifiedChinese:
            "简体中文"
        case .traditionalChinese:
            "繁體中文"
        case .japanese:
            "日本語"
        case .thai:
            "ไทย"
        }
    }

    static func matching(preferredLanguages: [String]) -> AppLanguage {
        let supportedCodes = allCases.compactMap(\.localizationCode)
        let matchedCode = Bundle.preferredLocalizations(
            from: supportedCodes,
            forPreferences: preferredLanguages
        ).first ?? AppLanguage.english.rawValue

        return allCases.first { $0.localizationCode == matchedCode } ?? .english
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    @Published private(set) var selection: AppLanguage
    @Published private(set) var relaunchFailed = false

    let activeSelection: AppLanguage

    var needsRelaunch: Bool {
        selection != activeSelection
    }

    var systemMatchedLanguage: AppLanguage {
        AppLanguage.matching(preferredLanguages: Self.systemPreferredLanguages)
    }

    init() {
        let storedSelection = Self.storedSelection
        selection = storedSelection
        activeSelection = storedSelection
    }

    @discardableResult
    func updateSelection(_ newSelection: AppLanguage) -> Bool {
        guard selection != newSelection else {
            return false
        }

        selection = newSelection
        relaunchFailed = false

        if let code = newSelection.localizationCode {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }

        UserDefaults.standard.synchronize()
        return true
    }

    func relaunch() {
        relaunchFailed = false

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = true

        NSWorkspace.shared.openApplication(
            at: Bundle.main.bundleURL,
            configuration: configuration
        ) { [weak self] _, error in
            Task { @MainActor in
                guard error == nil else {
                    self?.relaunchFailed = true
                    return
                }
                NSApplication.shared.terminate(nil)
            }
        }
    }

    func dismissRelaunchError() {
        relaunchFailed = false
    }

    private static var storedSelection: AppLanguage {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let applicationDomain = UserDefaults.standard.persistentDomain(
                  forName: bundleIdentifier
              ),
              let languages = applicationDomain["AppleLanguages"] as? [String],
              let preferredLanguage = languages.first else {
            return .system
        }

        return AppLanguage.matching(preferredLanguages: [preferredLanguage])
    }

    private static var systemPreferredLanguages: [String] {
        let globalDomain = UserDefaults.standard.persistentDomain(
            forName: UserDefaults.globalDomain
        )
        return globalDomain?["AppleLanguages"] as? [String] ?? Locale.preferredLanguages
    }
}
