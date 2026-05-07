# Product Definition

**Name:** Tora (Norse — "thunder", from Þóra/Tor)
**Platform:** macOS 14+ (Sonoma)
**Stack:** Swift / SwiftUI / SQLite (GRDB) / OpenAI API
**License:** MIT
**Repo:** github.com/stianbekk/tora-app

A menu bar app that watches Slack and Gmail, extracts actionable tasks using AI structured outputs, and surfaces them as task suggestions. Privacy-first: raw messages are never stored — only extracted task metadata persists locally in SQLite.

---

## Target User

Founder/CTO juggling Slack threads, Gmail, and client comms. Tasks get buried in conversation. Tora watches channels, detects actionable content, and surfaces it without leaving the workflow.

---

## Core Pipeline

```
Source (Slack/Gmail)
  → Local relay server (localhost:9377)
    → AI extraction (OpenAI structured output)
      → Suggestion (pending user action)
        → Task (accepted, stored in SQLite)
```

---

## Key Terms

| Term | Definition |
|------|-----------|
| **Source** | Connected channel (Slack workspace, Gmail account) |
| **Signal** | Incoming message that may contain actionable content |
| **Suggestion** | AI-extracted potential task, pending accept/dismiss |
| **Task** | Accepted suggestion with optional due date, priority, notes |
| **Customer** | Company/org the task relates to (AI-detected or manual) |
| **Product** | Product/project the task relates to (AI-detected or manual) |

---

## Scope

### v0 (MVP)

- Menu bar app shell with popover
- Slack Events API integration (1 workspace)
- OpenAI structured output extraction (configurable model)
- Suggestion cards with accept/dismiss + inline editing
- Local SQLite task storage with customer/product linking
- Task list window (filterable by customer/product/status)
- macOS native notifications (urgency-based)
- Settings: API key, Slack config, customer/product management
- Keyboard shortcuts
- First-run wizard
- Light/dark theme + accent color picker

### v1

- Gmail integration (Pub/Sub push)
- Task due date reminders
- Daily digest notification (morning summary)
- Drag-and-drop priority reordering
- Search across tasks and dismissed suggestions
- "Snooze" a suggestion (resurface later)
- Quick reply from suggestion (reply in Slack without leaving Tora)

### v2 Ideas

- Calendar awareness
- Sync to Linear / Notion / Todoist (plugin system)
- Local LLM option (Ollama)
- Spotlight integration
- Shortcuts.app actions
- Multi-device sync via iCloud
- iOS companion app

---

## Dependencies

| Package | Purpose | License |
|---------|---------|---------|
| GRDB.swift | SQLite ORM with Swift type safety | MIT |
| Hummingbird | Lightweight embedded HTTP server | Apache 2.0 |
| KeychainAccess | macOS Keychain wrapper | MIT |
