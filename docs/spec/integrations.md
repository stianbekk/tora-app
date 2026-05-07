# Input Source Integrations

## Slack (v0)

### Integration Method

Slack App with Events API. During development, ngrok tunnels webhooks to localhost:9377.

### Required Scopes

| Scope | Purpose |
|-------|---------|
| `channels:history` | Read public channel messages |
| `groups:history` | Read private channel messages |
| `im:history` | Read direct messages |
| `users:read` | Resolve user names |

### Events Subscribed

- `message.channels`
- `message.groups`
- `message.im`

### Filtering Logic

1. All messages in subscribed channels → process through AI extraction
2. Bot messages → skip (configurable)
3. AI decides what's actionable — no pre-filtering by @mention or watch list
4. Deduplication via message hash prevents reprocessing edits

### Why Process Everything?

Important tasks often arrive without an @mention. "Can someone update the pricing doc" in #megaflis is actionable even without a tag. Let the AI decide relevance, not string matching.

### Dev Setup (ngrok)

```bash
ngrok http 9377
# Copy the https URL to Slack app Event Subscriptions
# e.g. https://abc123.ngrok.io/slack/events
```

---

## Gmail (v1)

### Integration Method

Gmail API + Google Cloud Pub/Sub.

### Flow

1. User authenticates via OAuth2 (scope: `gmail.readonly`)
2. App calls `users.watch()` to register Pub/Sub topic
3. On push notification, app calls `users.history.list()` for new messages
4. New messages filtered and sent through extraction pipeline

### Filtering Logic

1. Only process emails in INBOX (skip sent, spam, promotions)
2. Skip automated/noreply senders
3. Skip newsletters (unsubscribe header present)
4. Process emails from known contacts with higher priority

### Watch Renewal

Must call `users.watch()` every 7 days. App schedules automatic renewal.
