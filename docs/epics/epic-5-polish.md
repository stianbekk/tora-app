# Epic 5: Polish

> Keyboard shortcuts, theming, app lifecycle, fuzzy matching.

**Wave:** 5
**Status:** Not started
**Depends on:** Wave 4

---

## Wave 5-A: Keyboard Shortcuts

**Depends on:** Wave 3 (all UI views exist)
**Parallel with:** 5-B, 5-C, 5-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 5.1 | Global hotkey: toggle popover | [ ] | ⌘⇧T via `NSEvent.addGlobalMonitorForEvents` |
| 5.2 | Accept focused suggestion | [ ] | ⌘↵ when popover is active |
| 5.3 | Dismiss focused suggestion | [ ] | ⌘⌫ when popover is active |
| 5.4 | Quick add task | [ ] | ⌘N opens manual task creation |
| 5.5 | Navigate suggestions | [ ] | ↑/↓ moves focus through suggestion list |
| 5.6 | Open task list | [ ] | ⌘L opens/focuses task list window |
| 5.7 | Mark complete | [ ] | ⌘D toggles completion on focused task |
| 5.8 | Shortcut remapping | [ ] | Store custom bindings in settings, re-register monitors |

---

## Wave 5-B: Theming Engine

**Depends on:** Wave 1-C (design system)
**Parallel with:** 5-A, 5-C, 5-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 5.9 | System appearance tracking | [ ] | `.preferredColorScheme` follows system, or manual override |
| 5.10 | Accent color picker | [ ] | 5 presets (Tora purple, amber, emerald, crimson, slate). See `docs/spec/design.md` |
| 5.11 | Menu bar icon variant | [ ] | Toggle between mascot, bolt, rune in settings |
| 5.12 | Persist theme preferences | [ ] | Store in SQLite settings table, apply on launch |

---

## Wave 5-C: App Lifecycle

**Depends on:** Wave 1-A (app shell)
**Parallel with:** 5-A, 5-B, 5-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 5.13 | Launch at login | [ ] | `SMAppService.register` for login items |
| 5.14 | First-run detection | [ ] | Check settings for `first_run_complete`, show wizard if false |
| 5.15 | Graceful shutdown | [ ] | Stop relay server, close database, cancel pending API calls |
| 5.16 | Show/hide dock icon | [ ] | Toggle `NSApp.setActivationPolicy` based on setting |

---

## Wave 5-D: Customer/Product Matching

**Depends on:** Wave 1-B (data layer)
**Parallel with:** 5-A, 5-B, 5-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 5.17 | Fuzzy name matching | [ ] | Match AI-returned names against local customer/product tables |
| 5.18 | Match confidence threshold | [ ] | Only auto-link if similarity > threshold, otherwise leave unlinked |
| 5.19 | Suggestion enrichment | [ ] | Populate `customer_id` and `product_id` on suggestion creation |
| 5.20 | New entity prompt | [ ] | When no match found on accept, offer to create new customer/product |
