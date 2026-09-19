# ShotSwitch

Menu bar app for macOS that switches the screenshot format (⌘⇧3 / ⌘⇧4 / ⌘⇧5) with one click.

Use HEIC day to day (smaller files, HDR) and flip to PNG when you need to share a capture with people on Windows, Linux, Discord, or a CLI tool that can't open HEIC.

## Features

- Menu bar item shows the current format (`HEIC`, `PNG`, …).
- One-click toggle between HEIC and PNG (⌘T while the menu is open).
- Full list: HEIC, PNG, JPG, PDF, TIFF, GIF, BMP.
- HDR capture toggle. HDR screenshots only fit in HEIC, so the app turns HDR off automatically for any other format and restores it when you go back to HEIC. Without this, macOS fails with *"Error al escribir los datos de imagen"* / *"Error writing image data"*.
- Launch at login.
- No Dock icon, no window.

## How it works

It writes the same preferences the Terminal command would:

```sh
defaults write com.apple.screencapture type png
defaults write com.apple.screencapture captureHDR -bool false
```

Changes apply immediately to the keyboard shortcuts. The `screencapture` CLI ignores the `type` preference; use `screencapture -t png` there.

## Requirements

- macOS 14 or later.
- Xcode 15 or later to build.

## Build

```sh
xcodebuild -project ShotSwitch.xcodeproj -scheme ShotSwitch -configuration Release build
```

Or open `ShotSwitch.xcodeproj` in Xcode and press ⌘R. Copy the resulting `.app` to `/Applications` and enable "Abrir al iniciar sesión" from the menu.

## Why no App Store

Writing to `com.apple.screencapture` requires the app to run **outside** the App Sandbox, which the Mac App Store does not allow. Distribute it as a notarized Developer ID build instead.

## Release (Developer ID + notarization)

```sh
scripts/release.sh
```

Produces `dist/ShotSwitch-<version>.dmg`, signed with Developer ID, notarized and stapled. One-time setup is described at the top of the script.
