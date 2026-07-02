# ClipDeck

English | [中文简体](README.zh-CN.md)

ClipDeck is a macOS clipboard shelf for collecting, searching, previewing, and organizing copied text and images with custom pinboards.

It is built with SwiftUI and AppKit, runs as a bottom-attached floating panel, and is designed around a translucent Liquid Glass-style interface.

## Features

- Global shortcut to show or hide the clipboard shelf
- Clipboard history for text and images
- Image preview and image pasteboard restore
- Search by clip content, type, source app, or group name
- Custom groups with colors, rename, delete, and clip assignment
- Keyboard navigation with left and right arrow keys
- Delete selected clips with `Delete` or `Backspace`
- Copy selected clips with `Command-C`
- Paste selected clips directly back into the previously focused app
- Delete all records, or remove records from a specific source app
- Local-only persistence

## Privacy Filters

ClipDeck includes configurable privacy filters to reduce the chance of sensitive content being saved into local history:

- Ignore common password managers, such as 1Password, Bitwarden, Dashlane, LastPass, and KeePass
- Ignore private browser windows, such as Private Browsing, Incognito, InPrivate, or Chinese private browsing markers
- Ignore common sensitive text, such as verification codes, private keys, API keys, access tokens, refresh tokens, and client secrets
- Add source apps to a custom ignored-app list, and remove them later from settings

Note: image contents cannot be inspected reliably for codes, keys, or confidential documents. Images are filtered by source app and private browsing state only.

## Usage

After launch, ClipDeck runs as a background utility and shows the bottom clipboard shelf. The default shortcut is:

```text
Option Space
```

You can type directly in the shelf to search, or click the search icon to expand or collapse the search field. Select a clip, then copy, delete, or paste it using the keyboard or mouse.

## Build And Run

Requirements:

- macOS 14 or later
- Swift 6 toolchain

Run tests:

```bash
swift test
```

Build and launch the app:

```bash
./script/build_and_run.sh
```

Build and verify that the app launches:

```bash
./script/build_and_run.sh --verify
```

## Accessibility Permission

ClipDeck may request macOS Accessibility permission. This permission is used to restore focus to the previously active app and send the paste shortcut after you choose a clip, enabling direct paste into the current insertion point.

Clipboard collection, local history, and search do not require network access.

## Data Storage

ClipDeck stores clipboard history in the current user's Application Support directory through `LibrarySnapshotStore`, using a local JSON snapshot.

If you frequently copy passwords, keys, verification codes, personal information, screenshots, or confidential documents, enable privacy filters and clear history regularly.

## Open Source Notice

ClipDeck is inspired by modern clipboard shelf workflows and pinboard-style organization patterns.

This project is independent and is not affiliated with, endorsed by, sponsored by, or authorized by Paste or pasteapp.io. Paste and pasteapp.io are trademarks or properties of their respective owners.

## License

ClipDeck is released under the MIT License. See [LICENSE](LICENSE).
