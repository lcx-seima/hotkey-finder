# Hotkey Finder

[English](README.md) | **简体中文**

Hotkey Finder 是一款原生 macOS 快捷键侦测工具。将窗口保持在前台并按下快捷键，它会结合键盘事件的目标进程、App 激活变化以及可选的可见窗口变化，判断哪个 App 响应了快捷键。

## 环境要求

- macOS 14 或更高版本
- Xcode 26 或更高版本
- 需要授予“输入监控”权限
- 可选授予“屏幕录制”权限，用于识别 Alfred 等不会激活自身的 App

屏幕录制权限仅用于比较窗口编号、所属进程和尺寸等元数据。Hotkey Finder 不会截取或保存屏幕内容。

项目没有第三方依赖，也不包含菜单栏入口。关闭最后一个窗口会退出 App。

## 本地签名

如果需要在 Xcode 中使用自己的 Apple Developer 账号运行 App，请创建本地签名配置：

```bash
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

然后在 `Config/Local.xcconfig` 中将 `DEVELOPMENT_TEAM` 设置为你的 Apple Developer Team ID。该文件已被 Git 忽略；关闭代码签名的命令行构建不需要此配置。

## 构建

```bash
xcodebuild \
  -project HotkeyFinder.xcodeproj \
  -scheme HotkeyFinder \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 语言设置

从 **Hotkey Finder > 设置…** 或按 `⌘,` 打开设置窗口，可选择：

- 跟随系统
- English
- 简体中文
- 繁體中文
- 日本語
- ไทย

选择“跟随系统”时，设置窗口会显示 Hotkey Finder 当前匹配到的语言。不支持的系统语言会回退到英语。更改语言后需要重启 App 才会生效。

## 人工验证

1. 用 Xcode 运行 App 并授予输入监控权限。如果 macOS 提示需要重启，请退出后重新运行。
2. 保持 Hotkey Finder 位于前台，按一个本地组合键，例如 `⌘P`，确认结果显示未侦测到响应的 App。
3. 可选授予屏幕录制权限，并按提示重启。这会启用针对 Alfred 等后台型 App 的窗口变化匹配。
4. 按一个已知的 Spotlight、Raycast 或 Alfred 全局快捷键，确认结果展示目标 App 的名称、图标、Bundle ID、PID 和侦测来源。
5. 按 F1–F20，确认能生成记录；长按按键不会持续产生重复记录。
6. 切换到其他 App，确认侦测暂停；返回 Hotkey Finder 后确认自动恢复。
7. 分别通过应用菜单和 `⌘,` 打开设置，切换语言并重启，确认主窗口与设置窗口都使用所选语言。
8. 连续产生超过 20 条记录，确认只保留最近 20 条；“清空记录”应删除全部记录。

## 已知边界

- 当前版本只做实时侦测，不扫描 App 菜单、系统快捷键设置、Karabiner、skhd 或其他配置文件。
- Hotkey Finder 使用 session event tap 尽早观察键盘事件；如果事件在进入用户会话前就被系统或驱动吞掉，仍可能无法侦测。
- 对于没有激活 App、没有暴露有效目标 PID、也没有产生可见窗口变化的快捷键，macOS 公开 API 无法可靠提供注册者。
- 窗口侦测通过比较快捷键前后的窗口集合推断目标；如果多个 App 同时创建窗口，结果可能存在误判。
- 仅记录带 `⌘`、`⌥`、`⌃`、`⇧` 的组合键以及 F1–F20；普通字符、仅修饰键和媒体键不会记录。
- 侦测历史只保存在内存中，退出 App 后会清空。
