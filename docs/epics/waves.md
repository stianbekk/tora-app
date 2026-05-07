# Wave Overview & Dependencies

## Execution Model

Work is organized into **Epics** (large feature areas) broken into **Waves** (parallelizable groups). Each wave contains tasks that can execute concurrently. A wave must complete before dependent waves start.

---

## Dependency Graph

```
Wave 1 (Foundation)
  ├─── 1-A: Project scaffolding ─────┐
  ├─── 1-B: Data models + schema ────┼──▶ Wave 2 + Wave 3
  └─── 1-C: Design system ───────────┘
                                       │
              ┌────────────────────────┤
              ▼                        ▼
        Wave 2 (Services)        Wave 3 (Core UI)
          ├─ 2-A: Relay server     ├─ 3-A: Menu bar + popover
          ├─ 2-B: AI extraction    ├─ 3-B: Task list window
          └─ 2-C: Notifications    ├─ 3-C: Settings window
              │                    └─ 3-D: First-run wizard
              │                        │
              └───────┬────────────────┘
                      ▼
                Wave 4 (Integration)
                  ├─ 4-A: Slack integration
                  └─ 4-B: End-to-end pipeline
                      │
                      ▼
                Wave 5 (Polish)
                  ├─ 5-A: Keyboard shortcuts
                  ├─ 5-B: Theming engine
                  ├─ 5-C: App lifecycle
                  └─ 5-D: Customer/product matching
                      │
                      ▼
                Wave 6 (Distribution)
                  ├─ 6-A: App icon + assets
                  ├─ 6-B: CI/CD
                  └─ 6-C: Documentation
                      │
                      ▼
                Wave 7 (v1 Features)
                  ├─ 7-A: Gmail integration
                  ├─ 7-B: Due date reminders
                  ├─ 7-C: Daily digest
                  └─ 7-D: Search + snooze
```

---

## Task Count Summary

| Wave | Epic | Tasks |
|------|------|-------|
| 1 | Foundation | 16 |
| 2 | Services | 20 |
| 3 | Core UI | 32 |
| 4 | Integration | 16 |
| 5 | Polish | 20 |
| 6 | Distribution | 13 |
| 7 | v1 Features | 18 |
| **Total** | | **135** |

---

## Critical Path (v0)

The fastest path to a working MVP:

1. **Wave 1** (all 3 tracks parallel) → project builds, data layer works, design tokens exist
2. **Wave 2-B** (AI extraction) + **Wave 3-A** (popover) → can show a suggestion card fed by AI
3. **Wave 2-A** (relay) + **Wave 4-A** (Slack) → real Slack messages reach the app
4. **Wave 4-B** (E2E pipeline) → accept/dismiss/task creation works end-to-end
5. **Wave 5** (polish) → keyboard shortcuts, theming, lifecycle
6. **Wave 6** (ship) → docs, CI, distribution
