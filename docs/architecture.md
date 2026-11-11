# Snapper architecture

How Snapper is put together and why. Read this before changing the snap rules, window placement or the shortcut
handling. The rules that follow from it are summarised in [AGENTS.md](../AGENTS.md).

Snapper is a resident accessory app: it listens for arrow keys with an exact modifier combination, works out which
state the focused window is in, and moves it to the next state with the Accessibility API. It differs from most window
managers only in copying the Windows 11 state machine and display wrapping.

| | |
|---|---|
| Resident UI | Menu-bar item (`AppDelegate` in `App.swift`) |
| Hotkeys | Session event tap (`KeyTap`), matching in `ShortcutModifier.variant` |
| Window access | Accessibility API (`WindowManager`): focused window, `AXPosition`, `AXSize`, `AXMinimized` |
| Decisions | `SnapRules.action`: a pure function of key, variant, current zone and display |
| Placement | `Zone.rect(in:)` on the display's usable area, `Geometry` for display choice and scaling |
| Settings | `defaults` domain `com.thoeksema.Snapper` (`Settings`) |
| Log | `~/Library/Logs/Snapper/snapper.log` (`Log`) |

## Process model

One per-user accessory app (no Dock icon) at `~/Applications/Snapper.app`, registered as a login item with
`SMAppService`. Everything runs on the main thread. A second launch exits immediately: two copies would both consume
the shortcut keys.

The event tap needs Accessibility access to exist at all. Until it is granted, `AppDelegate` asks for it and retries
every 1.5 s; the timer stops as soon as the tap is created, so an idle Snapper has no timers.

## Key handling

```
key down ─► KeyTap callback ─► exact modifier match? ─no─► pass through
                                       │yes
                                       ▼
                 consume key (and its key-up), async to main ─► WindowManager.handle
                                       ▼
        focused window ─► zone ─► SnapRules.action ─► SnapAction ─► AX writes
```

- **Exact match.** Arrow keys also carry fn/numpad flags, so only the four real modifiers are compared, and they must
  equal the chosen preset (or the preset plus ⇧ for display moves, or plus ⌘ for the top/bottom-half variant). Any
  other combination, and every other key, passes through untouched.
- **Cheap callback.** The tap callback does a keycode lookup and a flag comparison; the snapping runs on the main
  queue afterwards. A tap that is slow gets disabled by macOS, so it is re-enabled if that happens.
- **No repeat.** Holding the keys must not re-snap repeatedly, but must not leak to the app either: auto-repeat events
  are consumed without acting, and the key-up of a consumed key-down is consumed too.

## The state machine

`SnapRules.action` is the whole behaviour, as a table over (direction, zone). The zones are `maximized`, the four
halves, the four quarters, and `other` (a free-floating window). Highlights:

| Key | From | Result |
|---|---|---|
| ← | free, maximized | left half |
| ← | top / bottom half | top-left / bottom-left quarter |
| ← | right half | restore |
| ← | left half or left quarter | same slot, mirrored, on the display to the left (wrapping) |
| ↑ | free, top quarter | maximized |
| ↑ | maximized | top half |
| ↑ | top half | nothing (there is nothing above) |
| ↑ | left / right half | top-left / top-right quarter |
| ↑ | bottom quarter | the half |
| ↓ | maximized, top half | restore |
| ↓ | free, bottom half or quarter | minimize (optional) |

→ is the mirror image of ←. The ⇧ variant keeps the zone and moves to the next display, wrapping; the ⌘ variant
(top/bottom half) ignores the current zone. With a single display, the edge cases do nothing instead of wrapping.

## Zone detection

A window's zone is not just its geometry: apps with a minimum size or an aspect ratio can't always reach the exact
rect we ask for. After every move `WindowManager` records the zone it applied together with the frame the app actually
settled on; if the window is still at that frame, the recorded zone wins. Otherwise the frame is compared with each
zone's rect on its display within a tolerance, and anything else is `other`. Windows are keyed by `CFHash` of their
`AXUIElement`; the maps are cleared if they grow past 500 entries.

## Placement

- **Coordinates.** All frames are in Accessibility space: origin at the top-left of the primary display, y down.
  `NSScreen.visibleFrame` (bottom-left origin, excluding menu bar and Dock) is converted once in `displayFrames()`.
  Displays are ordered left to right, which defines "next" and "previous".
- **Writes.** `setFrame` sets size, position, then size again: the first resize may be clamped by the old display,
  and the move can in turn clamp the size on the new one.
- **Restore.** The frame before the first snap is remembered; it is rescaled when the window moves to a display of a
  different size, and a window with no remembered frame gets a centred 60% frame.
- **Enhanced UI.** Apps that set `AXEnhancedUserInterface` (VoiceOver users, some Electron apps) animate and ignore
  rapid AX writes, so it is switched off for the duration of the move and restored.
- **Full-screen** windows are skipped.
