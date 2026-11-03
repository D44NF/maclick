# MacClick

MacClick brings the Windows-style right-click context menu actions that
macOS Finder lacks — new text files, copying a path, opening a terminal at
a folder, zipping/unzipping, and checksums — directly into Finder's own
contextual menu. Every action can be switched on or off individually from
the app, so you only keep the ones you actually use.

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
project.yml    XcodeGen project specification (source of truth)
```

## Building

The project file is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen). After changing
`project.yml`, regenerate it:

```sh
brew install xcodegen   # once
xcodegen generate
```

Then open `MacClick.xcodeproj` in Xcode.

Requirements before the first build:

1. Accept the Xcode license once, if you haven't already:
   `sudo xcodebuild -license`
2. In Xcode, select your Apple ID team for both the `MacClick` and
   `MacClickFinderSync` targets under *Signing & Capabilities* (a free
   personal team is enough for local development; App Groups require a
   signed-in team).

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
