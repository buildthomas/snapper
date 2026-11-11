# Agent notes

Snapper is a small, offline, trustworthy window-snapping tool for macOS 13+ that copies the Windows 11 Win+Arrow
behaviour. One Swift package, no dependencies.

| | |
|---|---|
| Code | `Sources/Snapper` (AppKit, Accessibility API, event tap), pure logic in `Sources/SnapperCore` |
| Tests | `Tests/SnapperCoreTests` |
| Lives in | Menu bar (accessory app, no Dock icon) |
| More | [README.md](README.md) (features), [docs/architecture.md](docs/architecture.md) (how it works) |

README.md describes the features. This file is the rulebook for agents writing or reviewing changes.

## Product principles

- **The owner makes the product decisions.** New features, changed behaviour, new defaults, shortcuts or menu layout:
  propose them (with options and a recommendation) and wait for a yes. Bug fixes and internal cleanups don't need that.
- **Windows 11 is the reference.** When a key sequence is ambiguous, match what Windows 11 does (including wrapping
  across displays and staying put when there is nothing further to go to), not what another Mac tool does.
- **Trustworthy by construction.** Small, readable code; no network; no dependencies at runtime; nothing stored beyond
  the settings. A user should be able to audit the whole app.
- **No runtime cost for the rest of the system.** 0% CPU when idle, no timers or polling once running, keystrokes
  that aren't ours never delayed or altered.
- **Plain, quiet UI.** Plain punctuation in UI text (a hyphen, not an em dash or middle dot); remembered settings
  instead of prompts.

## Hard rules

- **No network code.** No HTTP, sockets, update checks, telemetry, or packages that phone home.
- **No new runtime dependencies** (Swift packages, bundled libraries or assets) without the owner's approval. Use what
  the OS and the SDK already provide. Test-only dependencies are fine.
- **Never log or store key data, window titles or window contents.** Logs record lifecycle events and errors only; no
  temporary debug logging of keys either.
- **The event tap passes through everything that isn't an exact match.** Only arrow keys with exactly the chosen
  modifiers (`ShortcutModifier.variant`) are consumed, together with their key-up. The tap callback must stay cheap:
  no I/O, no AX calls, no blocking; the snapping itself runs asynchronously on the main thread.
- **Pure logic stays in `SnapperCore`.** Snap rules, zone rects, geometry and shortcut matching take plain values
  (no AppKit, no AX) so they are unit tested; `Snapper` stays thin glue around the OS.
- **Only the installed copy touches the login item**, per-user, never admin. Installs stay per-user too.
- **Errors are shown, never swallowed.** A failed login-item change tells the user; a `try?` or a log-only `catch`
  is for cases the user can't act on.
- **Docs and commit messages are about the tool itself**, described generically, not about any particular person's
  purpose for using it.
- **Agent tool environments can be virtualized and sandboxed.** An agent's own processes may see a private copy of
  `~/Library` and `defaults`, can't signal or relaunch the user's running copy, and can't grant Accessibility. Run
  installs, uninstalls and every check of them in the user's own terminal before concluding anything is broken.
  `swift build --disable-sandbox` may be needed inside a sandbox (SwiftPM's own sandbox can't nest).

## Conventions

- Comments: none by default; one line when the why isn't obvious; never a paragraph.
- Coordinates: window frames are in Accessibility space (origin top-left of the primary display, y down). Convert
  `NSScreen` frames once, in `WindowManager.displayFrames()`; everything else works in AX space.
- Zones are detected from the frame we last applied to a window (apps with minimum sizes can't hit the exact rect),
  falling back to geometry within a tolerance. Keep it that way.
- Settings: add a value with a safe default in `Settings`; validate on load; stored enum values are never renumbered
  (`ShortcutModifier` raw values are persisted).
- Support macOS 13+ on Apple silicon and Intel.

## Testing

- **Unit tests must pass:** `swift test` (CI: `.github/workflows/mac.yml`). A change to the snap rules, zones,
  geometry or shortcut matching comes with tests; the rules are a table of (key, zone) pairs, so add the row.
- **UI or shortcut changes:** run the checklist below on a real Mac, or ask the user to.

### Verification checklist (real Mac, tick in the PR)

1. `./install.sh` succeeds; the menu-bar icon appears; `--diagnostics` shows the bundle id and the right arch.
2. Without Accessibility the menu offers "Grant Accessibility Access…"; after granting, the shortcuts work without a
   relaunch.
3. ⌃⌥← / → / ↑ / ↓ walk a normal window through every state in the README table, in both directions.
4. Pressing ↑ repeatedly: maximized, then top half, then it stays on the top half.
5. With two or more displays: → at the right edge continues to the next display and wraps from the last to the
   first; ← wraps the other way; ⌃⌥⇧← / → keep the snap position.
6. The shortcuts work while a text field has focus; other key combinations still reach the app.
7. ⌃⌥↓ from a normal window minimizes; turning "Down Arrow Minimizes Window" off makes it do nothing.
8. Restore returns to the pre-snap size and position, including after moving across displays.
9. Launch at Login toggles and survives a log out/in; `./uninstall.sh` leaves nothing behind.

## Build

- Swift package (tools version 5.9, Swift 5 language mode). `swift build`, `swift test`.
- `install.sh` builds a release binary, assembles and signs `~/Applications/Snapper.app` (`Resources/Info.plist`,
  icon from `docs/logo.png` via `scripts/make-icon.sh`), and launches it. `uninstall.sh` must keep removing
  everything the app and installer add (app, login item, `defaults`, logs, the Accessibility entry).
- Keep `snapperVersion` (`Sources/SnapperCore/Version.swift`) and `CFBundleShortVersionString` in
  `Resources/Info.plist` in step.

## PR review checklist

- [ ] Product change? Approved by the owner (linked in the PR), or it's a pure fix/cleanup.
- [ ] Behaviour matches Windows 11 where the README claims it does; README table and the menu text updated.
- [ ] No network, telemetry or new runtime dependency.
- [ ] Event tap still passes through everything that isn't an exact match and does no work in the callback.
- [ ] Nothing new runs while idle (timers, polling, background threads).
- [ ] Nothing new written to disk or `defaults`; nothing that could contain keystrokes or window contents in logs.
- [ ] Logic lives in `SnapperCore` with tests; `Snapper` stays thin.
- [ ] Settings changes backward compatible (defaults, validation, stable raw values).
- [ ] `uninstall.sh` still removes everything `install.sh` and the app add.
- [ ] Docs and commit message describe the change generically.
- [ ] `swift test` passes; checklist run for UI or shortcut changes.
