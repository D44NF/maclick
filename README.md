# MacClick

MacClick brings the Windows-style right-click context menu actions that
macOS Finder lacks — new text files, copying a path, opening a terminal or
VS Code at a folder, zipping/unzipping, and checksums — directly into
Finder's own contextual menu. Every action can be switched on or off
individually from the app, so you only keep the ones you actually use.

It is built the way Apple would build it: a native SwiftUI settings app
plus a sandboxed Finder Sync app extension, no private APIs, no
accessibility hacks, no process injection.

## How it works

- **MacClick.app** — a small SwiftUI settings window listing every
  available action with a toggle. Preferences are written to an App Group
  shared with the extension.
- **MacClick FinderSync.appex** — a `FIFinderSync` Finder Sync extension
  embedded in the app. It reads the enabled actions from the shared App
  Group and contributes them to Finder's contextual menu.

Project structure:

```
App/           SwiftUI app target (settings UI)
FinderSync/    Finder Sync extension target (Finder menu integration)
Shared/        Code shared by both targets (feature model, App Group id)
Tests/         Unit tests for the shared logic
Config/        Local signing config, kept out of git (see Building below)
project.yml    XcodeGen project specification (source of truth)
```

## Building

`MacClick.xcodeproj` is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) and is not committed —
a generated project file can bake in locally selected signing settings,
which must never end up in this public repo.

Before the first build:

1. Accept the Xcode license once, if you haven't already:
   `sudo xcodebuild -license`
2. Copy `Config/Local.xcconfig.sample` to `Config/Local.xcconfig` and fill
   in your Apple Developer Team ID (Xcode > Settings > Accounts > your
   Apple ID > double-click your team; a free personal team works). This
   file is gitignored and is what makes signing survive regeneration —
   without it, Xcode resets the team every time and the build fails
   because the App Group entitlement has no team to provision against.
3. Generate and open the project:

```sh
brew install xcodegen   # once
xcodegen generate
open MacClick.xcodeproj
```

Run `xcodegen generate` again any time `project.yml` or the source file
layout changes (for example after pulling new commits).

## Running the Finder extension

Finder Sync extensions are never launched directly. After building and
running `MacClick.app` once:

1. Open **System Settings → General → Login Items & Extensions → Finder
   Extensions** (or the button in the app) and enable *MacClick
   FinderSync*.
2. Right-click a file, folder, or empty space in a Finder window to see
   the enabled actions.

macOS caches Finder extensions aggressively; if a change doesn't show up,
quit and relaunch Finder (`killall Finder`) or log out and back in.
