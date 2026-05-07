# Design Language

## Philosophy

- **Calm technology** — reduce anxiety, not add to it
- **Glanceable** — understand task state in < 2 seconds
- **Keyboard-first** — power users shouldn't need the mouse
- **Dark + light** — follows system appearance

---

## Typography

System fonts only — SF Pro for body, SF Mono for monospace.

| Usage | Font | Size | Weight |
|-------|------|------|--------|
| Window title | SF Pro | 13px | 600 (semibold) |
| Section header | SF Pro | 10-10.5px | 700 (bold), uppercase, 0.6 letter-spacing |
| Card title | SF Pro | 13.5px | 600 |
| Body text | SF Pro | 12-12.5px | 500 |
| Snippet/secondary | SF Pro | 11.5px | 400, italic |
| Mono values | SF Mono | 10.5-11px | 400 |
| Badge count | SF Pro | 10px | 700 |
| Pill/chip | SF Pro | 11.5px | 500 |
| Kbd shortcut | SF Pro | 10.5px | 500 |

---

## Colors

### Accent Presets

| Name | Hex | Usage |
|------|-----|-------|
| Tora (default) | `#5D4FE8` | Purple — primary brand |
| Amber | `#F59E0B` | Warm alternative |
| Emerald | `#10B981` | Green alternative |
| Crimson | `#EF4444` | Red alternative |
| Slate | `#64748B` | Neutral alternative |

### Light Mode Tokens

| Token | Value |
|-------|-------|
| `--bg` | `#ECEEF2` |
| `--surface` | `rgba(255,255,255,0.55)` |
| `--surface-2` | `rgba(255,255,255,0.38)` |
| `--surface-3` | `rgba(255,255,255,0.5)` |
| `--surface-chip` | `rgba(0,0,0,0.045)` |
| `--border` | `rgba(255,255,255,0.6)` |
| `--border-soft` | `rgba(0,0,0,0.06)` |
| `--border-strong` | `rgba(0,0,0,0.12)` |
| `--text` | `#0E1116` |
| `--text-2` | `#2c3038` |
| `--text-3` | `#4f5560` |
| `--text-4` | `#7a8090` |
| `--accent-soft` | `rgba(accent, 0.16)` |
| `--menubar` | `rgba(245,245,247,0.6)` |

### Dark Mode Tokens

| Token | Value |
|-------|-------|
| `--bg` | `#0A0B0E` |
| `--surface` | `rgba(34,36,42,0.5)` |
| `--surface-2` | `rgba(28,30,36,0.5)` |
| `--surface-3` | `rgba(60,62,70,0.5)` |
| `--surface-chip` | `rgba(255,255,255,0.07)` |
| `--border` | `rgba(255,255,255,0.10)` |
| `--border-soft` | `rgba(255,255,255,0.06)` |
| `--border-strong` | `rgba(255,255,255,0.18)` |
| `--text` | `#F2F3F5` |
| `--text-2` | `#d6d9df` |
| `--text-3` | `#9aa0aa` |
| `--text-4` | `#6c7280` |
| `--accent-soft` | `rgba(accent, 0.24)` |
| `--menubar` | `rgba(28,28,30,0.5)` |

---

## Shadows

| Token | Light | Dark |
|-------|-------|------|
| `shadow-pop` | `0 24px 60px rgba(15,15,25,0.22)` | `0 30px 80px rgba(0,0,0,0.6)` |
| `shadow-card` | `0 1px 0 white(0.55) inset, 0 1px 2px rgba(0,0,0,0.05)` | `inset white(0.05), 0 1px 2px rgba(0,0,0,0.3)` |
| `shadow-window` | `0 30px 80px rgba(15,15,25,0.32)` | `0 40px 100px rgba(0,0,0,0.65)` |

---

## Glass Effects

| Token | Value |
|-------|-------|
| `glass-blur` | `blur(40px) saturate(180%)` |
| `glass-blur-strong` | `blur(60px) saturate(200%)` |

---

## Component Styles

### Buttons

| Style | Background | Text | Height | Radius |
|-------|-----------|------|--------|--------|
| Primary | `--accent` | `--accent-fg` (white) | 28px | 7px |
| Secondary | `--surface-3` + glass | `--text` | 28px | 7px |
| Ghost | transparent | `--text-2` | 26px | 6px |

### Pills/Chips

- Height: 22px, border-radius: 999px
- Background: `--surface-chip`
- Border: 0.5px solid `--border-soft`
- Font: 11.5px, weight 500

### Kbd (keyboard shortcut)

- Min-width: 18px, height: 18px
- Background: `--surface-chip`
- Border: 0.5px solid `--border-strong`
- Border-radius: 4px
- Font: 10.5px, weight 500

### Focus Ring

- `box-shadow: 0 0 0 2px var(--accent-soft), 0 0 0 0.5px var(--accent)`

---

## Animations

| Name | Effect | Duration | Easing |
|------|--------|----------|--------|
| popIn | translateY(-6px) + scale(0.985) → origin | 0.16s | cubic-bezier(.2,.7,.3,1.1) |
| slideIn | translateY(8px) → origin | 0.22s | ease |
| toastIn | translateX(20px) + scale(0.96) → origin | 0.32s | cubic-bezier(.2,.7,.3,1.1) |
| fadeOut | → opacity:0 + scale(0.97) | 0.25-0.3s | ease |

---

## Menu Bar Icon Variants

| Variant | Description |
|---------|-------------|
| Mascot | Photoreal mascot image (default) |
| Bolt | Filled lightning bolt glyph |
| Rune | Stylized "T" rune — Norse-edged |

Badge count: accent background pill, 14px height, 10px bold text, right of icon.

---

## Assets

- **Mascot:** purple blob creature (`assets/tora-mascot.png`)
- Two variants available (round blob, cloud-style)
- Used at: 14-18px (menu bar), 36px (toast), 120px (first-run welcome)
