# Hotkey Finder

Hotkey Finder 是一个现代 macOS 原生快捷键侦测器。把窗口放在前台并按下快捷键，它会结合系统键盘事件的目标 PID、随后发生的 App 激活事件，以及可选的窗口变化，判断哪个 App 响应了该快捷键。

## 环境

- macOS 14 或更高版本
- Xcode 26 或更高版本
- 需要授予“输入监控”权限
- 可选授予“屏幕录制”权限，用于识别 Alfred 等不激活自身的 App；只读取窗口元数据，不截取画面

项目没有第三方依赖，也不包含状态栏入口。关闭主窗口会退出应用。

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

## 人工验证

1. 用 Xcode 运行应用，点击“授予输入监控权限”。如果系统要求重启应用，退出后重新运行。
2. 保持 Hotkey Finder 为前台窗口，按一个本地组合键，例如 `⌘P`，确认出现“未检测到外部响应 App”。
3. 点击“授予屏幕录制权限”，按系统提示重启应用。这项权限不影响基础侦测，但 Alfred 一类后台 App 需要它来进行窗口变化匹配。
4. 按一个已知的全局快捷键，例如 Spotlight、Raycast 或 Alfred 的快捷键，确认结果展示目标 App 的名称、图标、Bundle ID、PID 和侦测来源。
5. 按 F1–F20 中的按键，确认能生成记录；长按按键不会持续产生重复记录。
6. 切换到其他 App，确认侦测暂停；返回 Hotkey Finder 后确认自动恢复。
7. 连续产生超过 20 条记录，确认只保留最近 20 条；点击“清空记录”确认列表被清空。

## 已知边界

- 第一版只做实时侦测，不扫描 App 菜单、系统快捷键、Karabiner、skhd 或其他配置。
- Hotkey Finder 使用 session event tap 尽早观察键盘事件；如果事件在进入用户会话前就被系统或驱动吞掉，仍可能无法侦测。
- 对于没有激活 App、没有暴露有效目标 PID、也没有产生可见窗口变化的全局快捷键，系统公开 API 无法可靠提供注册者。
- 窗口侦测使用按键前后的窗口集合差异进行推断；如果多个 App 同时创建窗口，结果可能存在误判。
- 仅记录带 `⌘`、`⌥`、`⌃`、`⇧` 的组合键以及 F1–F20；普通字符、仅修饰键和媒体键不会记录。
- 侦测历史只保存在当前进程内，退出后清空。
