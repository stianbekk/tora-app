# Epic 3: Core UI

> Build all SwiftUI views — popover, task list, settings, first-run.

**Wave:** 3
**Status:** Not started
**Depends on:** Wave 1
**Parallel with:** Wave 2

Reference prototypes: JSX files in original spec zip.

---

## Wave 3-A: Menu Bar + Popover

**Depends on:** Wave 1-C (design system)
**Parallel with:** 3-B, 3-C, 3-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 3.1 | NSStatusItem setup | [ ] | Menu bar button with Tora glyph, badge count overlay |
| 3.2 | Glyph variants | [ ] | Mascot, bolt, rune — configurable in settings |
| 3.3 | Popover container | [ ] | `NSPopover` attached to status item, frosted glass background |
| 3.4 | Popover header | [ ] | Tora logo + name + settings gear button |
| 3.5 | Suggestion card view | [ ] | Source icon, person, channel, title, snippet, meta chips, accept/dismiss. See `docs/spec/ui.md` |
| 3.6 | Inline accept editor | [ ] | Edit title, customer, product, due, priority before confirming |
| 3.7 | Inbox overflow | [ ] | "N more in inbox" button → opens task list at Inbox filter |
| 3.8 | Empty inbox state | [ ] | "You're all caught up" message with checkmark illustration |
| 3.9 | Task summary footer | [ ] | "My tasks" with open count + completed today count |
| 3.10 | Sources status bar | [ ] | Slack/Gmail connection indicators with green dots |

---

## Wave 3-B: Task List Window

**Depends on:** Wave 1-C (design system)
**Parallel with:** 3-A, 3-C, 3-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 3.11 | Detached window | [ ] | `NSWindow` with traffic lights, title bar, search field |
| 3.12 | Sidebar | [ ] | Inbox, Today, All open, Completed sections with counts |
| 3.13 | Customer/product sidebar groups | [ ] | Dynamic sidebar items from customer/product tables |
| 3.14 | Task row view | [ ] | Checkbox, title, meta chips (due, customer, product), priority dot |
| 3.15 | Completed section | [ ] | Collapsible group with "Completed (N)" header |
| 3.16 | Inbox view | [ ] | Render suggestion cards in task list when Inbox selected |
| 3.17 | Filter header | [ ] | Filter + Sort + New task buttons |
| 3.18 | Task toggle complete | [ ] | Click checkbox → toggle, animate strikethrough |
| 3.19 | Search | [ ] | Filter tasks by title, customer, product text |

---

## Wave 3-C: Settings Window

**Depends on:** Wave 1-C (design system)
**Parallel with:** 3-A, 3-B, 3-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 3.20 | Settings window shell | [ ] | Detached `NSWindow` with sidebar tabs |
| 3.21 | General pane | [ ] | Launch at login toggle, show in dock toggle, appearance selector |
| 3.22 | Sources pane | [ ] | Connected sources list with status, configure button, channel picker |
| 3.23 | AI Extraction pane | [ ] | Model dropdown, API key field (masked, Keychain), batch interval, usage stats |
| 3.24 | Customers & Products pane | [ ] | List with task counts, add/edit/delete |
| 3.25 | Shortcuts pane | [ ] | Shortcut list with key chord display, remapping |
| 3.26 | Notifications pane | [ ] | Per-urgency toggles (high/medium/low) |

---

## Wave 3-D: First-Run Wizard

**Depends on:** Wave 1-C (design system)
**Parallel with:** 3-A, 3-B, 3-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 3.27 | Wizard window | [ ] | Detached window with progress bar (4 steps) |
| 3.28 | Welcome step | [ ] | Mascot image, app description, 3 value-prop cards. See `docs/spec/ui.md` |
| 3.29 | API Key step | [ ] | OpenAI key input, paste button, Keychain storage, privacy note |
| 3.30 | Connect Slack step | [ ] | "Add to Slack" button (opens browser for OAuth), scope list, skip option |
| 3.31 | Permissions step | [ ] | Notification, network, launch-at-login — status + allow buttons |
| 3.32 | Wizard flow logic | [ ] | Step navigation, validation, mark first-run complete in settings |
