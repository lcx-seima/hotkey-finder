import CoreGraphics
import Foundation

enum ShortcutFormatter {
    private static let functionKeyCodes: Set<CGKeyCode> = [
        122, 120, 99, 118, 96, 97, 98, 100, 101, 109,
        103, 111, 105, 107, 113, 106, 64, 79, 80, 90,
    ]

    private static let keyNames: [CGKeyCode: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y",
        17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=",
        25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U",
        33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'",
        40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        48: "Tab", 49: "Space", 50: "`", 51: "Delete", 53: "Esc",
        64: "F17", 79: "F18", 80: "F19", 90: "F20", 96: "F5", 97: "F6",
        98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11", 105: "F13",
        106: "F16", 107: "F14", 109: "F10", 111: "F12", 113: "F15",
        114: "Help", 115: "Home", 116: "Page Up", 117: "Forward Delete",
        118: "F4", 119: "End", 120: "F2", 121: "Page Down", 122: "F1",
        123: "←", 124: "→", 125: "↓", 126: "↑",
    ]

    static func isEligible(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        hasSupportedModifier(flags) || functionKeyCodes.contains(keyCode)
    }

    static func string(keyCode: CGKeyCode, flags: CGEventFlags) -> String {
        var components: [String] = []

        if flags.contains(.maskControl) {
            components.append("⌃")
        }
        if flags.contains(.maskAlternate) {
            components.append("⌥")
        }
        if flags.contains(.maskShift) {
            components.append("⇧")
        }
        if flags.contains(.maskCommand) {
            components.append("⌘")
        }

        components.append(displayName(for: keyCode))
        return components.joined()
    }

    private static func displayName(for keyCode: CGKeyCode) -> String {
        switch keyCode {
        case 36:
            String(localized: "Return")
        case 48:
            String(localized: "Tab")
        case 49:
            String(localized: "Space")
        case 51:
            String(localized: "Delete")
        case 53:
            String(localized: "Esc")
        case 114:
            String(localized: "Help")
        case 115:
            String(localized: "Home")
        case 116:
            String(localized: "Page Up")
        case 117:
            String(localized: "Forward Delete")
        case 119:
            String(localized: "End")
        case 121:
            String(localized: "Page Down")
        default:
            keyNames[keyCode]
                ?? String.localizedStringWithFormat(
                    String(localized: "KeyCode %d"),
                    Int(keyCode)
                )
        }
    }

    private static func hasSupportedModifier(_ flags: CGEventFlags) -> Bool {
        flags.contains(.maskCommand)
            || flags.contains(.maskAlternate)
            || flags.contains(.maskControl)
            || flags.contains(.maskShift)
    }
}
