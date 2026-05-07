# Epic 6: Distribution

> App icon, CI, documentation, packaging.

**Wave:** 6
**Status:** Not started
**Depends on:** Wave 5

---

## Wave 6-A: App Icon + Assets

**Depends on:** Wave 5 (polish complete)
**Parallel with:** 6-B, 6-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 6.1 | App icon | [ ] | Generate all required sizes from mascot for `AppIcon.appiconset` |
| 6.2 | Menu bar icon assets | [ ] | Export glyph variants as template images for `NSStatusItem` |
| 6.3 | Finalize mascot usage | [ ] | Ensure mascot renders correctly at all sizes (16px menu bar → 120px wizard) |

---

## Wave 6-B: CI/CD

**Depends on:** Wave 5
**Parallel with:** 6-A, 6-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 6.4 | GitHub Actions workflow | [ ] | Build + test on macOS runner |
| 6.5 | Code signing config | [ ] | Developer ID signing for distribution outside App Store |
| 6.6 | Notarization | [ ] | `xcrun notarytool` integration in CI |
| 6.7 | DMG packaging | [ ] | Create distributable DMG with drag-to-Applications |

---

## Wave 6-C: Documentation

**Depends on:** Wave 5
**Parallel with:** 6-A, 6-B

| # | Task | Status | Description |
|---|------|--------|-------------|
| 6.8 | README.md | [ ] | Project overview, screenshots, quick start, build instructions |
| 6.9 | docs/setup-slack.md | [ ] | Step-by-step Slack app creation, scopes, Events API config |
| 6.10 | docs/setup-gmail.md | [ ] | Gmail API setup, Pub/Sub config, OAuth (v1 placeholder) |
| 6.11 | docs/architecture.md | [ ] | System architecture diagram, component responsibilities |
| 6.12 | CONTRIBUTING.md | [ ] | Contribution guidelines, code style, PR process |
| 6.13 | LICENSE | [ ] | MIT license file |
