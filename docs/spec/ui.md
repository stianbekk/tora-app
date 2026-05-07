# UI Specification

Reference prototypes: JSX files in original spec zip (`src/popover.jsx`, `src/tasklist.jsx`, `src/settings.jsx`, `src/firstrun.jsx`, `src/toast.jsx`, `src/chrome.jsx`).

---

## Views

### Popover (menu bar dropdown)

Primary interaction surface. Opens from menu bar icon click or ⌘⇧T.

- **Header:** Tora mascot/logo + "Tora" label + settings gear button
- **Inbox section:**
  - "INBOX" label with pending count badge
  - Top suggestion card (full detail)
  - "N more in inbox" overflow → opens task list at Inbox filter
  - Empty state: "You're all caught up" with checkmark illustration
- **Task summary footer:**
  - "My tasks" button with open count pill + "N completed today"
  - Click → opens task list window with Today filter
- **Sources status bar:**
  - Slack/Gmail connection indicators (green dot = connected)
  - Version number (e.g. v0.1.0)

### Suggestion Card

Appears in popover (single, top) and task list Inbox view (all pending).

- **Header row:** source icon (Slack/Gmail) + person name + "· channel" + timestamp (right-aligned, mono)
- **Title:** 13.5px, bold, 1.35 line height
- **Snippet:** 12px, italic, 2-line clamp, `var(--text-3)` color
- **Meta chips (pills):**
  - Due date with clock icon (accent-tinted if high urgency)
  - Customer with building icon
  - Product with tag icon
- **Actions:** Accept (primary button) + Dismiss (secondary button)
- **Focused state:** `focus-ring` class (2px accent shadow)
- **Animations:** slideIn on appear, fadeOut on accept/dismiss

### Inline Accept Editor

Replaces suggestion card when user clicks to edit before accepting.

- **"ACCEPT AS TASK" header** (accent color, uppercase)
- **Title input:** editable, pre-filled from suggestion
- **2×2 grid of dropdowns:**
  - Customer (with options from local table)
  - Product (with options from local table)
  - Due (Today, Tomorrow, This week, Next week)
  - Priority (High, Medium, Low)
- **Actions:** Save task (primary) + Cancel (secondary)
- **Shortcut hint:** ↵ save

### Task List Window (detached)

Full task management. Opens via popover footer or ⌘L.

- **Window:** `NSWindow` with traffic lights, title "Tora — Tasks", search field in header
- **Sidebar (220px):**
  - Inbox (with pending count)
  - Today (with count)
  - All open (with count)
  - Completed (with count)
  - **Customers section:** dynamic items from customer table with task counts
  - **Products section:** dynamic items from product table with task counts
  - Active item: accent-soft background + accent text
- **Main pane:**
  - **Header:** filter label + count, Filter/Sort/New buttons (not shown for Inbox)
  - **Inbox mode:** renders suggestion cards (same as popover, full list)
  - **Task mode:** task rows
    - Checkbox (circle → check-circle on complete)
    - Title (strikethrough when completed)
    - Meta: due date, customer, product chips
    - Priority dot (accent=high, text-3=medium, text-4=low)
    - Completed timestamp (right-aligned)
  - **Completed section:** collapsible, "Completed (N)" header

### Settings Window (detached)

Preferences and configuration. Opens via popover gear icon.

- **Window:** title "Tora — Settings", 760×520
- **Sidebar tabs (200px):**
  - General (gear icon)
  - Sources (inbox icon)
  - AI Extraction (bolt icon)
  - Customers & Products (building icon)
  - Shortcuts (list icon)
  - Notifications (bell icon)

**General pane:**
- Launch at login (toggle)
- Show in Dock (toggle, default off)
- Appearance (dropdown: Match system / Light / Dark)

**Sources pane:**
- Connected sources list (Slack, Gmail) with:
  - Source logo (36×36)
  - Name + details (workspace, channel count, watch renewal date)
  - Status indicator (green dot + "Connected")
  - Configure button
- "Add source" button
- Watched channels section (pill chips with add button)

**AI Extraction pane:**
- Model selector (dropdown, default gpt-5.4-mini)
- API key field (masked, mono font, "stored in Keychain" note)
- Batch interval selector (dropdown, default 30 seconds)
- Usage stats grid (3 columns): messages processed, tasks extracted, cost this month

**Customers & Products pane:**
- List with source logo, name, active tasks count, associated product
- External link button per customer
- "Add customer" button

**Shortcuts pane:**
- List of all shortcuts with key chord display (`kbd` styled)
- Remappable

**Notifications pane:**
- Per-urgency toggles:
  - High urgency: banner + sound (toggle)
  - Medium urgency: silent notification (toggle)
  - Low urgency: badge only (toggle)

### First-Run Wizard

Shown on first launch. 4-step flow.

- **Window:** title "Set up Tora", 720×560
- **Progress bar:** 4 segments across top, filled segments = completed steps

**Step 1 — Welcome:**
- Mascot image (120×120, drop shadow)
- "Hi, I'm Tora" heading
- Description paragraph
- 3 value-prop cards in grid: Local-first, No mentions needed, Stay in flow

**Step 2 — API Key:**
- "Connect OpenAI" heading
- Cost estimate ($5/month)
- API key input with paste button
- "Get an API key" link to platform.openai.com
- Privacy note (accent-soft background)

**Step 3 — Connect Slack:**
- "Connect Slack" heading
- Slack logo card with "Add to Slack" button (opens browser)
- Required scopes list with checkmarks
- "Connect Slack later in Settings" skip option

**Step 4 — Permissions:**
- "macOS permissions" heading
- Permission rows: Notifications, Network access, Launch at login
- Each shows granted status or "Allow" button

**Footer:** step counter (mono), Back button, Continue/Open Tora button

### Notification Toast

System-level in-app notification for new suggestions.

- **Position:** absolute, top-right under menu bar
- **Content:** Tora mascot (36×36), "Tora · now", task title, source meta
- **Actions:** Accept (primary) + Dismiss (secondary)
- **Animation:** toastIn (slide from right + scale)

---

## Interactions

| Action | Shortcut | Description |
|--------|----------|-------------|
| Toggle popover | ⌘⇧T | Open/close Tora popover |
| Accept suggestion | ⌘↵ | Accept focused suggestion as task |
| Dismiss suggestion | ⌘⌫ | Dismiss focused suggestion |
| Quick add task | ⌘N | Manually add a task |
| Navigate suggestions | ↑/↓ | Move through suggestion list |
| Open task list | ⌘L | Open full task list window |
| Mark complete | ⌘D | Toggle completion on focused task |
