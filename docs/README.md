# Tora Docs

## Spec

Product specification broken into domains:

- [product.md](spec/product.md) — product definition, scope (v0/v1/v2), dependencies
- [architecture.md](spec/architecture.md) — system components, technical decisions
- [database.md](spec/database.md) — SQLite schema, all tables, matching logic
- [ui.md](spec/ui.md) — all views (popover, task list, settings, wizard, toast), interactions
- [design.md](spec/design.md) — colors, typography, shadows, animations, component styles
- [integrations.md](spec/integrations.md) — Slack (v0) and Gmail (v1) integration details

## Epics

Implementation broken into waves with parallel execution:

- [waves.md](epics/waves.md) — dependency graph, task counts, critical path
- [epic-1-foundation.md](epics/epic-1-foundation.md) — project scaffolding, data models, design system
- [epic-2-services.md](epics/epic-2-services.md) — relay server, AI extraction, notifications
- [epic-3-core-ui.md](epics/epic-3-core-ui.md) — popover, task list, settings, first-run wizard
- [epic-4-integration.md](epics/epic-4-integration.md) — Slack integration, end-to-end pipeline
- [epic-5-polish.md](epics/epic-5-polish.md) — keyboard shortcuts, theming, lifecycle, fuzzy matching
- [epic-6-distribution.md](epics/epic-6-distribution.md) — app icon, CI/CD, documentation
- [epic-7-v1-features.md](epics/epic-7-v1-features.md) — Gmail, reminders, digest, search/snooze
