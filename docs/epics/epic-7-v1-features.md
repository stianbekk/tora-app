# Epic 7: v1 Features

> Post-MVP features: Gmail, reminders, search, snooze.

**Wave:** 7
**Status:** Not started
**Depends on:** Wave 6 (v0 shipped)

---

## Wave 7-A: Gmail Integration

**Depends on:** Wave 6 (v0 shipped)
**Parallel with:** 7-B, 7-C, 7-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 7.1 | Gmail OAuth2 flow | [ ] | `gmail.readonly` scope, token in Keychain |
| 7.2 | `users.watch()` setup | [ ] | Register Pub/Sub topic for inbox notifications |
| 7.3 | Watch renewal scheduler | [ ] | Auto-renew every 7 days |
| 7.4 | History list processing | [ ] | On push notification, call `users.history.list()` for new messages |
| 7.5 | Email filtering | [ ] | Skip sent/spam/promotions, skip noreply/newsletters (unsubscribe header) |
| 7.6 | Route to extraction pipeline | [ ] | Same AI extraction as Slack, with `source: "gmail"` |
| 7.7 | Gmail source configuration | [ ] | Settings UI for Gmail connection, account display, watch status |

---

## Wave 7-B: Due Date Reminders

**Depends on:** Wave 6
**Parallel with:** 7-A, 7-C, 7-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 7.8 | Reminder scheduling | [ ] | Schedule local notifications for tasks with due dates |
| 7.9 | Reminder preferences | [ ] | How far in advance to remind (1 hour, morning of, day before) |
| 7.10 | Overdue detection | [ ] | Flag tasks past due date, surface in popover |

---

## Wave 7-C: Daily Digest

**Depends on:** Wave 6
**Parallel with:** 7-A, 7-B, 7-D

| # | Task | Status | Description |
|---|------|--------|-------------|
| 7.11 | Morning summary notification | [ ] | Scheduled notification with today's tasks count + high-priority items |
| 7.12 | Digest time preference | [ ] | Configurable time for morning summary |
| 7.13 | Digest content | [ ] | Tasks due today, overdue tasks, pending suggestions count |

---

## Wave 7-D: Search + Snooze

**Depends on:** Wave 6
**Parallel with:** 7-A, 7-B, 7-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 7.14 | Full-text search | [ ] | Search across task titles, notes, customer/product names |
| 7.15 | Search dismissed suggestions | [ ] | Include dismissed suggestions in search results |
| 7.16 | Snooze suggestion | [ ] | "Remind me later" — hide suggestion, resurface at chosen time |
| 7.17 | Snooze options | [ ] | 1 hour, tomorrow morning, next week, custom date/time |
| 7.18 | Quick reply from suggestion | [ ] | Reply to Slack message without leaving Tora (Slack API `chat.postMessage`) |
