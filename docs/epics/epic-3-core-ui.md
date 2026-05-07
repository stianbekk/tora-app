# Epic 3: Core UI

> Build all SwiftUI views — popover, task list, settings, first-run.

**Wave:** 3
**Status:** Complete
**Depends on:** Wave 1
**Parallel with:** Wave 2

Reference prototypes: JSX files in original spec zip.

---

## Wave 3-A: Menu Bar + Popover

**Depends on:** Wave 1-C (design system)
**Parallel with:** 3-B, 3-C, 3-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 3.1 | NSStatusItem setup | [x] | Menu bar button with Tora glyph, badge count overlay |
| 3.2 | Glyph variants | [x] | Mascot, bolt, rune — configurable in settings |
| 3.3 | Popover container | [x] | `NSPopover` attached to status item, frosted glass background |
| 3.4 | Popover header | [x] | Tora logo + name + settings gear button |
| 3.5 | Suggestion card view | [x] | Source icon, person, channel, title, snippet, meta chips, accept/dismiss. See `docs/spec/ui.md` |
| 3.6 | Inline accept editor | [x] | Edit title, customer, product, due, priority before confirming |
| 3.7 | Inbox overflow | [x] | "N more in inbox" button → opens task list at Inbox filter |
| 3.8 | Empty inbox state | [x] | "You're all caught up" message with checkmark illustration |
| 3.9 | Task summary footer | [x] | "My tasks" with open count + completed today count |
| 3.10 | Sources status bar | [x] | Slack/Gmail connection indicators with green dots |

---

## Wave 3-B: Task List Window

**Depends on:** Wave 1-C (design system)
**Parallel with:** 3-A, 3-C, 3-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 3.11 | Detached window | [x] | `NSWindow` with traffic lights, title bar, search field |
| 3.12 | Sidebar | [x] | Inbox, Today, All open, Completed sections with counts |
| 3.13 | Customer/product sidebar groups | [x] | Dynamic sidebar items from customer/product tables |
| 3.14 | Task row view | [x] | Checkbox, title, meta chips (due, customer, product), priority dot |
| 3.15 | Completed section | [x] | Collapsible group with "Completed (N)" header |
| 3.16 | Inbox view | [x] | Render suggestion cards in task list when Inbox selected |
| 3.17 | Filter header | [x] | Filter + Sort + New task buttons |
| 3.18 | Task toggle complete | [x] | Click checkbox → toggle, animate strikethrough |
| 3.19 | Search | [x] | Filter tasks by title, customer, product text |

---

## Wave 3-C: Settings Window

**Depends on:** Wave 1-C (design system)
**Parallel with:** 3-A, 3-B, 3-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 3.20 | Settings window shell | [x] | Detached `NSWindow` with sidebar tabs |
| 3.21 | General pane | [x] | Launch at login toggle, show in dock toggle, appearance selector |
| 3.22 | Sources pane | [x] | Connected sources list with status, configure button, channel picker |
| 3.23 | AI Extraction pane | [x] | Model dropdown, API key field (masked, Keychain), batch interval, usage stats |
| 3.24 | Customers & Products pane | [x] | List with task counts, add/edit/delete |
| 3.25 | Shortcuts pane | [x] | Shortcut list with key chord display, remapping |
| 3.26 | Notifications pane | [x] | Per-urgency toggles (high/medium/low) |

---

## Wave 3-D: First-Run Wizard

**Depends on:** Wave 1-C (design system)
**Parallel with:** 3-A, 3-B, 3-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 3.27 | Wizard window | [x] | Detached window with progress bar (4 steps) |
| 3.28 | Welcome step | [x] | Mascot image, app description, 3 value-prop cards. See `docs/spec/ui.md` |
| 3.29 | API Key step | [x] | OpenAI key input, paste button, Keychain storage, privacy note |
| 3.30 | Connect Slack step | [x] | "Add to Slack" button (opens browser for OAuth), scope list, skip option |
| 3.31 | Permissions step | [x] | Notification, network, launch-at-login — status + allow buttons |
| 3.32 | Wizard flow logic | [x] | Step navigation, validation, mark first-run complete in settings |
