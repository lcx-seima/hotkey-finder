<div align="center">
  <img src="HotkeyFinder/Assets.xcassets/AppIcon.appiconset/AppIcon-256.png" width="128" height="128" alt="Hotkey Finder icon">
  <h1>Hotkey Finder</h1>
  <p>A native macOS utility for finding the app behind a keyboard shortcut.</p>
  <p><strong>English</strong> · <a href="README.zh-CN.md">简体中文</a></p>
</div>

<div align="center">
  <img src="docs/assets/demo.gif" width="400" alt="Hotkey Finder detecting the app behind a keyboard shortcut">
</div>

Hotkey Finder helps answer a deceptively difficult question: **which app just handled that shortcut?** Keep Hotkey Finder in front, press the shortcut you want to inspect, and it correlates several macOS signals to identify the most likely responding app.

## ShortcutDetective Alternative

Hotkey Finder is a macOS alternative to [ShortcutDetective](https://www.irradiatedsoftware.com/labs/), inspired by its simple and focused approach. Thanks to Irradiated Software for the original idea.

## Features

- Identifies an app from the keyboard event target, app activation, or a newly visible window
- Shows the app name, icon, bundle identifier, PID, and detection method
- Force-quits an identified app after an explicit confirmation
- Records shortcuts with modifiers and function keys from F1 through F20
- Keeps the latest 20 results and ignores key-repeat noise
- Pauses detection whenever Hotkey Finder is not the active app
- Supports English, Simplified Chinese, Traditional Chinese, Japanese, and Thai
- Built entirely with Apple frameworks, with no third-party dependencies

## How It Works

For every shortcut, Hotkey Finder tries the strongest available signals in order:

1. It checks the process targeted by the keyboard event.
2. It observes whether another app becomes active immediately afterward.
3. With optional Screen Recording access, it compares visible-window metadata to find apps such as Alfred that open a panel without becoming active.
4. If none of these signals identifies another process, it reports that no responding app was detected.

Detection is best-effort because macOS does not expose a public API that reliably reports the owner of every global shortcut.

## Requirements

- macOS 14 or later
- Xcode 26 or later when building from source
- Input Monitoring access
- Optional Screen Recording access for window-based detection

## Download

Download the latest build from [GitHub Releases](https://github.com/lcx-seima/hotkey-finder/releases/latest), or use the [direct download link](https://github.com/lcx-seima/hotkey-finder/releases/latest/download/Hotkey-Finder.zip).

> [!WARNING]
> The downloadable app is currently **ad-hoc signed, not Developer ID signed, and not notarized**. macOS cannot verify its developer or check it through Apple's notarization service. Only continue if you downloaded it from this repository and accept that limitation. Installing an update may require granting privacy permissions again.

To open the app for the first time:

1. Unzip it, move **Hotkey Finder.app** to `/Applications`, and try to open it once.
2. After macOS blocks it, open **System Settings > Privacy & Security**.
3. Scroll to **Security**, click **Open Anyway** for Hotkey Finder, authenticate, then confirm **Open**.

This creates an exception for this app; it does not require disabling Gatekeeper globally. The **Open Anyway** button is available for about an hour after a blocked launch attempt. See [Apple's safety guidance](https://support.apple.com/en-us/102445) before overriding the warning.

For an integrity check, download `Hotkey-Finder.zip.sha256` from the same release and run:

```bash
shasum -a 256 -c Hotkey-Finder.zip.sha256
```

## Build and Run

To run Hotkey Finder from Xcode:

```bash
git clone https://github.com/lcx-seima/hotkey-finder.git
cd hotkey-finder
cp Config/Local.xcconfig.example Config/Local.xcconfig
open HotkeyFinder.xcodeproj
```

Set `DEVELOPMENT_TEAM` in `Config/Local.xcconfig` to your Apple Developer Team ID, select the **HotkeyFinder** scheme, and run the app. `Config/Local.xcconfig` is ignored by Git.

To verify that the project builds without code signing:

```bash
xcodebuild \
  -project HotkeyFinder.xcodeproj \
  -scheme HotkeyFinder \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Usage

1. Launch Hotkey Finder and grant Input Monitoring access. Restart the app if macOS asks you to.
2. Keep the Hotkey Finder window in front.
3. Press the shortcut you want to inspect.
4. Review the detected app and detection method in the current result or recent activity.

Screen Recording access is optional, but it improves detection for background-style apps that show a window without becoming active. After changing either permission, macOS may require an app restart.

Hotkey Finder runs as a regular windowed app without a menu bar item. Closing its last window quits the app.

## Privacy and Permissions

Hotkey Finder uses a listen-only event tap and never changes or blocks keystrokes. Input Monitoring is active only while its window is in front.

Screen Recording access is used only to compare window metadata such as identifiers, owning processes, and sizes. Hotkey Finder does not capture or save screen content. Detection history stays in memory and is cleared when the app quits.

## Language

Open **Hotkey Finder > Settings…** or press `⌘,` to choose Follow System, English, Simplified Chinese, Traditional Chinese, Japanese, or Thai. Unsupported system languages fall back to English. Language changes take effect after restarting the app.

## Known Limitations

- Hotkey Finder performs live detection only. It does not scan app menus, System Settings, Karabiner, skhd, or other shortcut configuration files.
- Events consumed by the system or a driver before reaching the user session may be undetectable.
- A shortcut cannot be identified reliably if it exposes no target PID, activates no app, and creates no visible window.
- Window-based detection is inferred from before-and-after metadata; simultaneous window creation by multiple apps can produce a false match.
- Plain characters, modifier-only events, and media keys are ignored.

## Development Verification

Maintainers can find the ad-hoc-signed automated publishing setup in [docs/RELEASING.md](docs/RELEASING.md).

<details>
<summary>Manual verification checklist</summary>

1. Run the app and grant Input Monitoring access. If macOS requests a restart, quit and reopen the app.
2. Keep Hotkey Finder in front and press a local shortcut such as `⌘P`; verify that no external responding app is reported.
3. Optionally grant Screen Recording access and restart. Verify window-based matching with an app such as Alfred.
4. Press a known global shortcut for Spotlight, Raycast, or Alfred; verify the app name, icon, bundle identifier, PID, and detection method.
5. Use an app with no unsaved work to verify Kill can be canceled, requires confirmation, then force-quits the app and marks matching current and history results as exited.
6. Press F1 through F20 and verify records are created. Hold a key and verify repeated records are not created.
7. Switch to another app and verify detection pauses, then return and verify it resumes.
8. Change the language from both the app menu and `⌘,`, verify the shortcut does not change the current result or history, then restart and verify both windows use the selected language.
9. Create more than 20 records and verify only the latest 20 remain. Clear History should remove them all.

</details>
