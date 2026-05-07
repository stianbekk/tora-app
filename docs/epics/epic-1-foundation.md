# Epic 1: Foundation

> Set up the Xcode project, data layer, and shared UI primitives.

**Wave:** 1
**Status:** Not started

---

## Wave 1-A: Project Scaffolding

**Depends on:** nothing
**Parallel with:** 1-B, 1-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 1.1 | Create Xcode project | [ ] | macOS app, SwiftUI lifecycle, deployment target macOS 14 |
| 1.2 | Configure SPM dependencies | [ ] | GRDB.swift, Hummingbird, KeychainAccess |
| 1.3 | Set up directory structure | [ ] | `App/`, `Views/`, `Models/`, `Services/`, `Utilities/`, `Resources/` |
| 1.4 | Configure app as menu bar only | [ ] | `LSUIElement = YES`, no dock icon, `NSStatusItem` setup |
| 1.5 | Add mascot assets | [ ] | Import mascot PNGs into `Assets.xcassets`, app icon placeholder |
| 1.6 | Create `.gitignore` | [ ] | Xcode, Swift, macOS-appropriate ignores |

---

## Wave 1-B: Data Models + Schema

**Depends on:** nothing
**Parallel with:** 1-A, 1-C

| # | Task | Status | Description |
|---|------|--------|-------------|
| 1.7 | Define Swift models | [ ] | `Source`, `Customer`, `Product`, `Suggestion`, `Task`, `AppSettings` as `Codable` structs conforming to GRDB protocols |
| 1.8 | Create database manager | [ ] | GRDB `DatabaseQueue` setup at `~/Library/Application Support/Tora/tora.db` |
| 1.9 | Write migration 001 | [ ] | Create all tables: `sources`, `customers`, `products`, `suggestions`, `tasks`, `settings` |
| 1.10 | Implement CRUD operations | [ ] | Repository pattern: `SourceRepository`, `CustomerRepository`, `ProductRepository`, `SuggestionRepository`, `TaskRepository` |
| 1.11 | Add query helpers | [ ] | Filter tasks by status/customer/product/due date, count helpers for sidebar |

---

## Wave 1-C: Design System

**Depends on:** nothing
**Parallel with:** 1-A, 1-B

| # | Task | Status | Description |
|---|------|--------|-------------|
| 1.12 | Define color tokens | [ ] | Swift `Color` extensions matching CSS variables for light/dark. See `docs/spec/design.md` |
| 1.13 | Define typography | [ ] | Font styles matching SF Pro weights used in prototypes |
| 1.14 | Create shared components | [ ] | `PillView`, `KbdView`, button styles (primary, secondary, ghost) |
| 1.15 | Create icon set | [ ] | SF Symbols mapping for all icons used in prototypes (or custom SVG shapes) |
| 1.16 | Create card styles | [ ] | Glass-effect card with `.ultraThinMaterial` backdrop, shadow, corner radius |
