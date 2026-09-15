# Flicker

**[中文](README.md)** | English

<p align="center">
  <img src="screenshots/app-logo.png" alt="Flicker" width="256" />
</p>

<p align="center">
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-orange" alt="Swift 6.0" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT" /></a>
</p>

A minimalist macOS Finder right-click menu extension — open files and folders with your pre-configured apps instantly, copy paths, and create common files without leaving Finder.

## Screenshots

<p align="center">
  <img src="screenshots/image1.png" alt="Configuration UI" width="480" />
  <br/>
  <em>App configuration — set file extensions for each app</em>
</p>

<p align="center">
  <img src="screenshots/image2.png" alt="Finder context menu" width="480" />
  <br/>
  <em>Finder context menu — one-click open & path copying</em>
</p>

## Features

- Right-click files/folders to open with pre-configured applications
- Place configured apps either inside the Open With submenu or directly in the Finder context menu
- Copy absolute paths, project-relative paths, or file names to clipboard
- Create common file types from the Finder context menu, with optional auto-open after creation
- Configure app list with per-app file extension filters inside the container app
- "Folders only" mode for fine-grained menu visibility control
- Toggle Flicker's Finder context menu output, hide the Dock icon, and reduce main-window visibility in window managers

## Project Structure

```
Flicker/
├── App/          # App entry, config list, add/edit panels, store
├── Shared/       # AppEntry (data model), SharedStore (App Group read/write)
└── Resources/    # Info.plist, entitlements, Assets

FlickerExtension/   # Finder Sync extension (FIFinderSync subclass)
```

## Getting Started

### Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16+ (for building)

### Build & Run

```bash
# Command-line build
xcodebuild -project Flicker.xcodeproj -scheme Flicker -configuration Debug build

# Or open Flicker.xcodeproj in Xcode, select the Flicker scheme and hit Run
```

### Package as DMG

```bash
./scripts/build_dmg.sh
# Output: dist/Flicker-<version>.dmg
```

### Enable the Extension

1. Launch Flicker, click **Add** to select a `.app`, then set its name, file extensions, and menu collapse behavior
2. Click **Manage Finder Extension…** at the bottom, then check Flicker under **System Settings → Privacy & Security → Extensions → Finder**
3. Restart Finder (`killall Finder`) — right-click in Finder to see the menu

## Configuration After Forking

If you fork this project and plan to build your own copy, update these values to your own:

| Setting | Current Value | Location |
|---------|---------------|----------|
| Bundle Identifier (App) | `com.wangyanan.flicker` | `project.pbxproj` |
| Bundle Identifier (Extension) | `com.wangyanan.flicker.extension` | `project.pbxproj` |
| App Group | `group.com.wangyanan.flicker` | `Shared/SharedStore.swift` |
| URL Scheme | `flicker` | `Resources/Info.plist` |

> **Tip:** App Group must be registered in the Apple Developer portal. For local development, ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`) works without a developer account.

## Technical Notes

- Project-relative paths use the deepest matching configured root, then the nearest Git root, falling back to absolute paths when neither is available.
- Configuration is shared between the app and extension via JSON files in the user's Application Support directory
- Finder Sync extensions are hosted by macOS; quitting Flicker does not unload the extension. To temporarily hide Flicker's menu output, disable **Enable Finder Context Menu** in Action Control
- Minimum deployment target: macOS 14.0 (Sonoma)

## Contributing

Issues and Pull Requests are welcome!

- Make sure the code compiles and runs before submitting a PR
- Open an issue first to discuss new features
- Keep code style consistent with the existing codebase

## License

This project is licensed under the [MIT License](LICENSE).

### iCloud Drive path services

When Finder Sync menus are unavailable in iCloud Drive (including synced Documents/Desktop), install the rebuilt app in Applications and launch it once. Select files or folders in Finder and choose **Services → 复制绝对路径 / 复制项目内路径 / 复制文件名** (copy absolute path / project-relative path / filename). Enable the entries or assign shortcuts in System Settings → Keyboard → Keyboard Shortcuts → Services if needed; logging out and back in may be necessary.

Services are managed independently of Flicker's Finder menu toggles. Multiple selections produce newline-separated text. The implementation only formats supplied file URLs; it does not read or explicitly download file contents. These are local filesystem paths, not iCloud sharing links.

Open **项目目录** (Project Directories) in the app sidebar to add multiple root folders, search, or remove entries. Settings persist without code edits. Manually configured roots take priority (deepest match wins); otherwise the nearest `.git` directory or worktree `.git` file is detected automatically. Both Finder and Services use the same resolver in the container app.

For example, configuring `/Users/charli/Documents/TCM` yields `outputs/result.txt` without a leading slash. Selecting the root itself yields `.`. Unknown projects fall back to absolute paths. Each selected item is resolved independently. Finder automation permission is no longer needed. Re-add configured roots after moving their folders.

See the Chinese README for the standalone Swift regression test command and the Finder/iCloud manual verification checklist.
