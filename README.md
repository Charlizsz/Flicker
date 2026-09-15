# Flicker

中文 | **[English](README_EN.md)**

<p align="center">
  <img src="screenshots/app-logo.png" alt="Flicker" width="256" />
</p>

<p align="center">
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-orange" alt="Swift 6.0" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT" /></a>
</p>

极简的 macOS Finder 右键菜单扩展，让你用预配置的应用程序快速打开文件或文件夹，并快速完成路径复制、新建文件等常用操作。

## 截图

<p align="center">
  <img src="screenshots/image1.png" alt="配置界面" width="480" />
  <br/>
  <em>应用配置界面 — 为每个 App 设置适用的文件扩展名</em>
</p>

<p align="center">
  <img src="screenshots/image2.png" alt="Finder 右键菜单效果" width="480" />
  <br/>
  <em>Finder 右键菜单效果 — 一键打开、复制路径</em>
</p>

## 功能

- 对文件/文件夹右键，可选择用预配置的应用程序打开
- 打开方式支持折叠到「打开方式」子菜单，或直接显示在 Finder 右键一级菜单中
- 复制选中项的绝对路径、项目内路径或文件名到剪贴板
- 支持在 Finder 右键菜单中新建常用文件类型，并可设置创建后自动打开
- 容器 App 内配置可用应用程序列表（含每个应用适用的文件扩展名）
- 支持「仅文件夹」模式，灵活控制菜单项显示范围
- 支持一键关闭 Flicker 的 Finder 右键菜单输出，并可隐藏程序坞图标或减少主窗口在窗口管理中的展示

## 工程结构

```
Flicker/
├── App/          # 应用入口、配置列表、添加/编辑面板、Store
├── Shared/       # AppEntry（配置模型）、SharedStore（App Group 共享读写）
└── Resources/    # Info.plist、entitlements、Assets

FlickerExtension/   # Finder Sync 扩展（FIFinderSync 子类）
```

## 快速开始

### 系统要求

- macOS 14.0（Sonoma）或更高版本
- Xcode 16+（构建）

### 构建与运行

```bash
# 命令行构建
xcodebuild -project Flicker.xcodeproj -scheme Flicker -configuration Debug build

# 或在 Xcode 中打开 Flicker.xcodeproj，选 Flicker scheme 直接运行
```

### 打包 DMG

```bash
./scripts/build_dmg.sh
# 产物位于 dist/Flicker-<version>.dmg
```

### 首次启用扩展

1. 运行容器 App，点击「添加」选择 `.app`、设置名称、适用扩展名与菜单折叠方式
2. 点击底部「管理 Finder 扩展…」，在 **系统设置 → 隐私与安全性 → 扩展 → 访达** 中勾选 Flicker
3. 重启 Finder（`killall Finder`）后右键即可见

## Fork 后需要修改的配置

如果你 Fork 了本项目并打算自己构建使用，请注意以下配置需要修改为你自己的值：

| 配置项 | 当前值 | 文件位置 |
|--------|--------|----------|
| Bundle Identifier（App） | `com.wangyanan.flicker` | `project.pbxproj` |
| Bundle Identifier（Extension） | `com.wangyanan.flicker.extension` | `project.pbxproj` |
| App Group | `group.com.wangyanan.flicker` | `Shared/SharedStore.swift` |
| URL Scheme | `flicker` | `Resources/Info.plist` |

> **提示：** App Group 需要在 Apple Developer 后台注册后才能使用。本地开发可使用 ad-hoc 签名（`CODE_SIGN_IDENTITY = "-"`），无需开发者账号。

## 技术说明

- 项目内路径优先匹配手动配置的项目根目录，其次自动识别最近的 Git 根目录；找不到时回退为绝对路径。两个菜单入口使用同一套规则。
- 配置通过用户 Application Support 目录中的 JSON 文件在 App 与扩展间共享
- Finder Sync 扩展由 macOS 托管，退出 Flicker 主 App 不等于卸载扩展；如需临时关闭 Flicker 菜单，可在「操作控制」中关闭「启用 Finder 右键菜单」
- 最低系统版本 macOS 14.0（Sonoma）

## 贡献

欢迎提交 Issue 和 Pull Request！

- 提交 PR 前请确保代码可以正常编译运行
- 新功能请先开 Issue 讨论可行性
- 请保持代码风格与现有代码一致

## 许可证

本项目基于 [MIT License](LICENSE) 开源。

### iCloud Drive：通过「服务」复制路径

对于 Finder Sync 菜单无法出现的 iCloud Drive（包括同步的 Documents / Desktop），可使用主 App 提供的系统服务：

1. 构建新版 Flicker，将 `Flicker.app` 放入「应用程序」并运行一次。
2. 在访达选中文件或文件夹，右键 → **服务**，选择 **复制绝对路径 / 复制项目内路径 / 复制文件名**。多选结果以换行分隔。
3. 若没有显示，在系统设置 → 键盘 → 键盘快捷键 → 服务中启用对应项目，也可设置快捷键。必要时注销并重新登录。

服务独立于「操作控制」中的 Finder 菜单开关，由系统服务设置管理。绝对路径和文件名只处理系统传入的文件 URL，代码不会读取文件内容或主动下载 iCloud 文件。路径是这台 Mac 的文件系统路径，不是 iCloud 分享链接。

在主窗口左侧打开 **项目目录**，点击「添加项目文件夹…」，可一次选择多个项目根文件夹。支持搜索、移除和重启后保留设置，无需修改代码。Git 项目无需手动添加：会自动识别最近的 `.git` 文件夹或 worktree 的 `.git` 文件。手动配置优先，嵌套配置选择匹配最深的根目录；普通前缀相似的文件夹不会误匹配。

例如添加 `/Users/charli/Documents/TCM` 后，复制其下 `outputs/result.txt` 得到 `outputs/result.txt`，不带开头的 `/`。选中项目根目录本身得到 `.`。找不到项目根目录时保留绝对路径，不猜测 Documents 下哪一层是项目。多选时每个文件分别匹配所属项目。

此功能不再读取访达窗口或要求自动化权限。Finder 扩展将选中文件的路径交给主 App 统一处理，服务入口直接由主 App 执行。手动目录移动后需在列表中重新添加。

开发验证（需要匹配的 macOS SDK 与 Swift 6 工具链）：

```sh
mkdir -p build
swiftc -swift-version 6 Flicker/Shared/PathFormatter.swift Flicker/Shared/SharedStore.swift Flicker/Shared/AppEntry.swift Flicker/Shared/MenuSettings.swift Flicker/App/ProjectPaths.swift Flicker/App/PathServices.swift tests/PathServicesTests.swift -o build/path-services-tests
build/path-services-tests
```

发布前请在 Finder 中验证：本地和 iCloud 文件/文件夹、未下载的 iCloud 文件、中文及空格文件名、多选、项目配置保存与移除、嵌套目录、Git 自动识别、App 未运行时调用服务，以及原 Finder 右键菜单。测试程序使用独立剪贴板，不改写用户的通用剪贴板。

### 1.5 更新来源

此 Fork 的版本号为 **1.5**。应用内的自动/手动检查更新、仓库和反馈入口均指向 [Charlizsz/Flicker](https://github.com/Charlizsz/Flicker)，不查询上游仓库。更新检测只提示并打开 Release 下载页，不会自动安装或覆盖应用。没有公开正式 Release 时，手动检查会说明暂无发布版本，自动检查保持静默。后续需要在本仓库发布版本号更高的正式 Release（例如 `v1.6`）才会提示更新；仅推送代码不会触发版本更新。

打包脚本明确构建 `arm64 + x86_64` 通用版本，可在 Intel 或 Apple Silicon Mac 上执行。生成 DMG 前会检查主应用和 Finder 扩展是否同时包含两种架构，缺少任一架构则停止打包。
