# Hotkey Finder

**English** | [简体中文](README.zh-CN.md)

Hotkey Finder is a native macOS utility that helps identify which app responds to a keyboard shortcut. Keep its window in front and press a shortcut; it correlates the keyboard event's target process, app activation changes, and—when enabled—newly visible windows.

## Requirements

- macOS 14 or later
- Xcode 26 or later
- Input Monitoring access
- Optional Screen Recording access for apps such as Alfred that do not become active

Screen Recording access is used only to compare window metadata such as identifiers, owning processes, and sizes. Hotkey Finder does not capture or save screen content.

The project has no third-party dependencies or menu bar item. Closing its last window quits the app.

## Build

```bash
xcodebuild \
  -project HotkeyFinder.xcodeproj \
  -scheme HotkeyFinder \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Language

Open **Hotkey Finder > Settings…** or press `⌘,` to choose one of the following:

- Follow System
- English
- Simplified Chinese
- Traditional Chinese
- Japanese
- Thai

When following the system, Settings shows the language that Hotkey Finder will use. Unsupported system languages fall back to English. A language change takes effect after the app restarts.

## Manual Verification

1. Run the app from Xcode and allow Input Monitoring. If macOS asks you to restart the app, quit and run it again.
2. Keep Hotkey Finder in front and press a local shortcut such as `⌘P`; verify that the result says no responding app was detected.
3. Optionally allow Screen Recording and restart when prompted. This enables window-based matching for background-style apps such as Alfred.
4. Press a known global shortcut for Spotlight, Raycast, or Alfred; verify the target app's name, icon, bundle identifier, PID, and detection method.
5. Press keys from F1 through F20 and verify that records are created. Holding a key should not create repeated records.
6. Switch to another app and verify detection pauses, then return to Hotkey Finder and verify it resumes.
7. Open Settings from both the app menu and `⌘,`, change the language, restart, and verify both windows use the selected language.
8. Create more than 20 records and verify only the latest 20 remain. Clear History should remove them all.

## Known Limitations

- This version performs live detection only. It does not scan app menus, system shortcut settings, Karabiner, skhd, or other configuration files.
- Hotkey Finder uses a session event tap to observe keyboard events early. Events consumed by the system or a driver before reaching the user session may still be undetectable.
- Public macOS APIs cannot reliably identify a shortcut owner when there is no app activation, valid target PID, or visible window change.
- Window detection infers the target by comparing windows before and after a shortcut. Simultaneous window creation by multiple apps can produce a false match.
- Only shortcuts containing `⌘`, `⌥`, `⌃`, or `⇧`, plus F1–F20, are recorded. Plain characters, modifier-only events, and media keys are ignored.
- Detection history is stored in memory and is cleared when the app quits.
