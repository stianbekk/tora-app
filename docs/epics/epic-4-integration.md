# Epic 4: Integration

> Wire Slack to the relay server and connect the full pipeline end-to-end.

**Wave:** 4
**Status:** Complete
**Depends on:** Wave 2 + Wave 3

---

## Wave 4-A: Slack Integration

**Depends on:** Wave 2-A (relay server), Wave 2-B (AI extraction)

| # | Task | Status | Description |
|---|------|--------|-------------|
| 4.1 | Slack OAuth2 flow | [x] | Open browser → Slack OAuth → receive token → store in Keychain |
| 4.2 | Parse Slack event payloads | [x] | Deserialize `message.channels`, `message.groups`, `message.im` events |
| 4.3 | Filter bot messages | [x] | Skip messages from bots (configurable) |
| 4.4 | Resolve user names | [x] | Call Slack `users.info` API, cache user ID → name mapping |
| 4.5 | Channel resolution | [x] | Map channel IDs to readable names, cache |
| 4.6 | Route to extraction | [x] | Forward parsed message to AI extraction service |
| 4.7 | Create suggestion from result | [x] | If `is_actionable`, create `Suggestion` row, match customer/product |
| 4.8 | Trigger notification | [x] | Based on urgency, fire appropriate notification |
| 4.9 | ngrok dev setup | [x] | Document ngrok setup, add tunnel URL config for Slack Events API |

---

## Wave 4-B: End-to-End Pipeline

**Depends on:** Wave 4-A, Wave 3-A (popover), Wave 3-B (task list)

| # | Task | Status | Description |
|---|------|--------|-------------|
| 4.10 | Suggestion → popover binding | [x] | New suggestions appear in popover in real-time |
| 4.11 | Accept flow | [x] | Accept suggestion → create Task → mark suggestion accepted → update counts |
| 4.12 | Dismiss flow | [x] | Dismiss suggestion → mark dismissed → animate out → update counts |
| 4.13 | Inline edit → task | [x] | Edited fields (title, customer, product, due, priority) persist to created task |
| 4.14 | Toast notification | [x] | New high-urgency suggestion triggers in-app toast with accept/dismiss |
| 4.15 | Customer/product auto-create | [x] | When accepting with new customer/product name, offer to create entry |
| 4.16 | Manual task creation | [x] | "New" button in task list → create task without suggestion |
