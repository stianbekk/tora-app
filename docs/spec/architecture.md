# Architecture

## Components

### 1. Menu Bar Shell (SwiftUI)

- Lives exclusively in macOS menu bar (no dock icon by default)
- Clicking menu bar icon opens popover panel
- Badge count shows pending suggestions
- Popover shows top suggestion + task summary
- "View →" opens detached task list window

### 2. Local Relay Server (Hummingbird)

Lightweight HTTP server on `localhost:9377`. Receives webhooks from Slack Events API and Gmail Pub/Sub.

- **Dev:** ngrok tunnels Slack/Gmail to localhost
- **Production:** small relay proxy on VPS or Cloudflare Worker forwards via websocket/SSE

```
Internet                          │           Your Mac
                                  │
Slack Events API ──── POST ──────▶│──▶ localhost:9377/slack/events
Gmail Pub/Sub    ──── POST ──────▶│──▶ localhost:9377/gmail/push
                                  │
                            Tunnel / relay
```

**Endpoints:**

| Route | Method | Purpose |
|-------|--------|---------|
| `/slack/events` | POST | Slack Events API receiver + `url_verification` challenge |
| `/gmail/push` | POST | Google Cloud Pub/Sub push (v1) |
| `/health` | GET | Health check |

### 3. AI Extraction Layer (OpenAI)

- Model: configurable, default `gpt-5.4-mini`
- Structured outputs — guaranteed valid JSON matching schema
- Messages buffered 30s, sent in batches
- Cost estimate: ~$5.40/month at 500 messages/day

**Extraction Schema:**

```json
{
  "is_actionable": boolean,
  "task": {
    "title": string,
    "source_channel": string,
    "source_person": string,
    "urgency": "low" | "medium" | "high",
    "suggested_due": ISO date | null,
    "context_snippet": string (1-2 sentences),
    "customer": string | null,
    "product": string | null
  } | null
}
```

**System prompt context includes:** source type, user identity, what to look for (deadlines, customer references, product mentions).

### 4. Data Layer (SQLite / GRDB)

- Database at `~/Library/Application Support/Tora/tora.db`
- Tables: `sources`, `customers`, `products`, `suggestions`, `tasks`, `settings`
- Customer/product fuzzy matching against local tables
- Deduplication via SHA256 hash of original message
- No raw message storage

### 5. Notification System

- macOS `UNUserNotificationCenter`
- High urgency → immediate notification with sound
- Medium urgency → silent notification, badge update
- Low urgency → badge count only
- Per-source notification preferences

---

## Technical Decisions

**Why Swift/SwiftUI over Electron/Tauri?**
Native menu bar apps need tight OS integration (notifications, keychain, appearance). SwiftUI gives this for free. Binary size ~5MB vs 100MB+ for Electron. Runs 24/7 — must sip resources.

**Why Hummingbird over Vapor?**
Lighter weight. Purpose-built for embedded server use cases. Vapor brings too much framework overhead for a localhost relay.

**Why GRDB over Core Data?**
Direct SQL access with Swift type safety. Core Data is overkill and its migration tooling is painful for a fast-moving OSS project.

**Why configurable model with GPT-5.4-mini default?**
Task extraction is classification + structured extraction from short messages. Structured outputs guarantee valid JSON — no parsing failures. Settings dropdown allows swapping models.

**Why process all Slack messages?**
Important tasks often arrive without @mention. AI is better at determining relevance than regex. At ~$5/month, worth it for not missing things.

**Why Events API over Socket Mode?**
Socket Mode requires persistent websocket — less reliable for a menu bar app that may sleep/wake. Events API + relay is more robust and mirrors Gmail's Pub/Sub, keeping architecture consistent.
