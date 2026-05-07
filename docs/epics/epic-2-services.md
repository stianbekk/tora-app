# Epic 2: Services

> Build the backend services that process signals and produce suggestions.

**Wave:** 2
**Status:** Complete
**Depends on:** Wave 1

---

## Wave 2-A: Local Relay Server

**Depends on:** Wave 1-A (project exists)
**Parallel with:** 2-B, 2-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 2.1 | Set up Hummingbird server | [x] | Initialize HTTP server on `localhost:9377` within app process |
| 2.2 | Add health endpoint | [x] | `GET /health` returns 200 with status JSON |
| 2.3 | Add Slack events endpoint | [x] | `POST /slack/events` — receives webhook payloads, handles `url_verification` challenge |
| 2.4 | Add Gmail push endpoint | [x] | `POST /gmail/push` — receives Pub/Sub notifications (stub for v1) |
| 2.5 | Add request validation | [x] | Verify Slack signing secret on incoming webhooks |
| 2.6 | Server lifecycle management | [x] | Start on app launch, stop on quit, handle port-in-use errors |

---

## Wave 2-B: AI Extraction Service

**Depends on:** Wave 1-B (models exist)
**Parallel with:** 2-A, 2-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 2.7 | Create OpenAI API client | [x] | HTTP client for `chat.completions` with structured output (`response_format`) |
| 2.8 | Define extraction schema | [x] | JSON Schema for `task_extraction` matching spec. See `docs/spec/architecture.md` |
| 2.9 | Implement system prompt | [x] | Template with `{source}` placeholder, extraction instructions |
| 2.10 | Build message buffer | [x] | 30-second batching — accumulate signals, batch-process |
| 2.11 | Parse extraction response | [x] | Decode structured output → `Suggestion` model, handle `is_actionable: false` |
| 2.12 | Deduplication | [x] | SHA256 hash of message content, skip if hash exists in `suggestions` |
| 2.13 | Model configuration | [x] | Read model name from settings, default `gpt-5.4-mini`, expose in Settings UI |
| 2.14 | Usage tracking | [x] | Count messages processed, tasks extracted, cost estimate per month |

---

## Wave 2-C: Notification Service

**Depends on:** Wave 1-A (project exists)
**Parallel with:** 2-A, 2-B

| # | Task | Status | Description |
|---|------|--------|-------------|
| 2.15 | Request notification permission | [x] | `UNUserNotificationCenter.requestAuthorization` |
| 2.16 | High urgency notifications | [x] | Banner + sound, fire immediately on high-urgency suggestion |
| 2.17 | Medium urgency notifications | [x] | Silent notification (no sound), badge update |
| 2.18 | Low urgency handling | [x] | Badge count update only |
| 2.19 | Notification actions | [x] | "Accept" and "Dismiss" actions on notification banner |
| 2.20 | Badge count management | [x] | Update `NSStatusItem` badge count on suggestion create/act |
