# Contributing to Define

Thanks for helping out! Define is deliberately small: a SwiftPM package, no
third-party dependencies, AppKit shell + SwiftUI views.

## Getting started

```sh
git clone https://github.com/daniel-inderos/Define.git && cd Define
swift build
swift test
make run        # build Define.app and launch it
```

You can also open `Package.swift` directly in Xcode. When running un-bundled
(Xcode or `swift run`), macOS ties Accessibility permission to the binary
path and may re-prompt after rebuilds — that's normal; the bundled build
(`make app`) has a stable identity.

## Architecture

```
Sources/Define/
├── DefineApp.swift            # @main entry point
├── AppDelegate.swift          # wires everything together
├── AppState.swift             # observable UI state + lookup flow
├── StatusItemController.swift # menu bar item + popover
├── Hotkey/                    # CGEventTap that intercepts ⌃⌘D
├── Selection/                 # reads the selected text (AX API, ⌘C fallback)
├── Dictionary/                # DictionaryServices lookup, term cleanup, formatting
├── Permissions/               # Accessibility permission watching
├── Store/                     # SwiftData models + WordStore (all writes)
├── Export/                    # Anki TSV generation
└── Views/                     # SwiftUI popover UI
```

The flow for a lookup: hotkey or menu bar click →
`SelectionReader.currentSelection()` → `TermNormalizer.normalize` →
`DefinitionService.lookUp` → `WordStore.recordLookup` → popover UI.

A few conventions:

- **All model writes go through `WordStore`** so dedupe/counter rules live in
  one place and stay testable.
- **No third-party dependencies.** Part of the point of the app is that it's
  small, auditable, and fully offline.
- **System-integration code** (event taps, AX calls, pasteboard) is isolated
  in its own layer and kept out of the views.

## Tests

`swift test` runs everything. The pure logic (term normalization, definition
formatting, Anki escaping, store rules) is covered; code that needs
Accessibility permission or a GUI session (event tap, selection reading) is
exercised manually. If you change formatting heuristics in
`DefinitionFormatter`, please add a test with a realistic raw dictionary
string.

## Pull requests

- Keep PRs focused; separate refactors from behavior changes.
- `swift test` must pass.
- For UI changes, include a screenshot of the popover.
- For new lookup/formatting heuristics, mention which apps/dictionaries you
  tested against — this code is full of per-app quirks, and that context is
  gold for reviewers.

## Reporting selection bugs

The most valuable bug report for this app: an application where selection
reading fails. Please include the app name and version, and whether the AX
path or the clipboard fallback was used (run with `make debug` and watch the
console).
