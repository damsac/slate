---
id: "001"
title: "Initial Build: Slate Todo App"
status: active
author: gudnuf
project: Slate
tags: [swift, swiftui, swiftdata, widgetkit, xcodegen, nix, skills, dx]
previous: "000"
sessions:
  # Build session (~/home dir, project created here)
  - id: 1b07722a
    slug: initial-app-build-and-deployment
    dir: home
  # TodoFlow era (~/TodoFlow)
  - id: 625b0c33
    slug: project-exploration-and-rename-planning
    dir: TodoFlow
  - id: 7c225cde
    slug: rename-execution
    dir: TodoFlow
  - id: 327b4856
    slug: data-model-update
    dir: TodoFlow
  - id: 4890e479
    slug: ui-modernization-planning
    dir: TodoFlow
  - id: 5510d316
    slug: plan-handoff-to-slate
    dir: TodoFlow
  # Slate era (~/Slate)
  - id: b173c239
    slug: design-system-implementation
    dir: Slate
  - id: fcd05f8e
    slug: skills-and-prompt-workflow
    dir: Slate
  - id: be7a7f80
    slug: open-xcode-skill
    dir: Slate
  - id: b98cc24c
    slug: swift-nix-reproducibility
    dir: Slate
prompts: []
created: "2026-02-08T01:01:00Z"
updated: "2026-02-08T05:45:00Z"
---

# 001: Initial Build — Slate Todo App

## Context

Built the TodoFlow app from the implementation prompt created in [000-research-and-ideation.md](000-research-and-ideation.md), deployed it to a real iPhone, then renamed it to Slate and refined the UI and developer tooling. This meta covers everything from first line of code through a working app with design system and workflow automation.

## Timeline

### Phase 0: Initial Build & Deployment (`1b07722a`, ~3 hrs)

**What**: Built the entire TodoFlow app from the implementation prompt generated in [000-research-and-ideation.md](000-research-and-ideation.md). Went from zero code to a working app on a physical iPhone.

**Built in one session**:
- Main app: todo list with add/edit/check/delete/reorder
- Home screen widget (medium): shows 5 todos with tap-to-toggle via AppIntent
- Lock screen widgets (3 variants): rectangular with interactive buttons, circular, inline
- Local notifications with "Mark Done" action button
- Shared SwiftData persistence via App Group container
- XcodeGen project config (`project.yml`)

**Deployment progression**:
1. App running in simulator (~01:14 UTC)
2. Widget integration debugging — widget gallery wasn't discovering the extension, required rebuild + simulator reset
3. Lock screen widget research + implementation (~01:20-01:27) — interactive rectangular widget with Button+AppIntent (requires Face ID/Touch ID unlock per iOS security)
4. Physical device deployment (~01:27-01:42) — provisioning, developer mode, Xcode symbol sync, trust on device
5. App working on real iPhone (~01:49)
6. Notification actions added with 10-second test option (~01:50)

**Problems**:
- Widget not appearing in simulator widget gallery — required clean rebuild and sometimes simulator reset
- `SortDescriptor` needed explicit type annotation in widget module context
- Standard provisioning challenges for physical device (developer mode, trusting developer)
- `NotificationManager.swift` wasn't in `project.yml` initially — required XcodeGen regeneration

**DX created**: Comprehensive README + interactive `/setup` Claude Code skill for developer onboarding, documenting real problems encountered (provisioning, device deployment, widget discovery).

### Phase 1: Exploration & Rename Planning (`625b0c33`, ~10 min)

**What**: Developer requested a full architectural overview of the TodoFlow app, then decided to rename it to "Slate".

**Developer thinking**: Wanted comprehensive understanding before making changes — deployed an Explore subagent for deep analysis. Then pivoted to rebranding.

**Key decision — naming strategy**: The developer challenged a "replace everything" approach. Discussion about whether internal components should carry the brand name ("SlateWidget") or stay domain-descriptive ("TodoWidget"). Settled on a **hybrid approach**:
- **Brand-level**: bundle IDs (`com.slate.app`), app groups (`group.com.slate.shared`), project files, user-facing strings → use "Slate"
- **Domain-level**: internal structs like `TodoItem`, `TodoWidget` → keep "Todo" prefix (describes function, not brand)

The plan was created but the user interrupted to refine the naming strategy before execution.

### Phase 2: Rename Execution (`7c225cde`, ~10 min)

**What**: Comprehensive rename from TodoFlow → Slate. Highly directed operation — the developer had the full plan ready.

**Scope**: 12 files edited (content), 5 files renamed, 3 directories renamed.

**Execution order** (phased to avoid broken references):
1. Content edits first (bundle IDs, struct names, strings, entitlements)
2. File renames (`TodoFlowApp.swift` → `SlateApp.swift`, etc.)
3. Directory renames (`TodoFlow/` → `Slate/`, `TodoFlowWidget/` → `SlateWidget/`, `.xcodeproj`)

**Problems**: Xcode was actively modifying files during the rename (scheme reformatting, plist updates). Handled by re-reading before writing. Binary cache files (UserInterfaceState.xcuserstate) auto-regenerate so residual "todoflow" references in them were fine.

**Outcome**: Clean rename. Grep verified no remaining "todoflow" in text files.

### Phase 3: Data Model Update (`327b4856`, ~5 min)

**What**: Added new fields to `TodoItem` — a surgical, fast operation.

**Changes**:
- `doneAt: Date?` — timestamp when marked complete
- `todoType: TodoType` — enum `.today` | `.backlog` (defaults to `.today`)
- `dueDate: Date?` — optional due date

**Breaking change strategy**: Developer explicitly called for a clean break ("this a breaking change do it clean"). Schema version bumped to 2 with `deleteStoreIfSchemaChanged()` — nukes the SQLite store on version mismatch rather than attempting complex migration. Pragmatic for early development.

**Files**: `TodoItem.swift`, `PersistenceConfig.swift`, `TodoListView.swift`, `ToggleTodoIntent.swift`, `NotificationManager.swift`.

### Phase 4: UI Modernization Planning (`4890e479` + `5510d316`, ~20 min)

**What**: Developer wanted to transform a "2012-looking" app into something modern, but explicitly constrained scope: "only actually do the minimum to get it to a basic modern aesthetic" with "a strong foundation for a design and theme."

**Developer thinking**: Considered external UI packages but decided against — pure SwiftUI, no dependencies. Wanted a centralized `Theme.swift` so future rebranding is a single-file change.

**Planning process**: Subagent analyzed the full codebase (~8 min). Plan was created specifying exact changes per file. Developer interrupted the first plan, refined it, then copied the final plan to clipboard for execution in the new `~/Slate` directory.

**The plan specified**:
- `Theme.swift` enum with color tokens, spacing, corner radii, `priorityColor(_:)` helper
- Card-style rows with colored leading-edge priority indicators
- Floating input bar with material background
- Half-sheet edit view, `.snappy` animations, symbol effects
- Remove unused `Priority.color` from model

### Phase 5: Design System Implementation (`b173c239`, ~22 min)

**What**: Executed the plan from Phase 4 in the renamed `~/Slate` project. Developer pasted the plan directly into the conversation.

**Created**: `Slate/Theme/Theme.swift` — 10 color tokens, 5 spacing levels (xs→xl), 3 corner radii, `priorityColor(_:)` helper.

**Modified**: `TodoListView.swift` (major restyling — plain list, card backgrounds, floating input bar, animations), `TodoItem.swift` (removed `Priority.color`), `TodoWidgetView.swift` (use Theme), `project.yml` (Theme.swift in widget sources).

**Problems**:
- XcodeGen wasn't installed in the Nix environment — worked with existing `.xcodeproj`
- Code signing errors on CLI build — solved with `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO`
- Widget target couldn't find Theme.swift — added to sources in `project.yml`

**Outcome**: Build succeeded. Net -13 lines while adding significant visual polish.

### Phase 6: DX Skills (`fcd05f8e` + `be7a7f80`, ~1.5 hrs)

**What**: Built project-specific Claude Code skills to streamline the development workflow.

#### open-xcode skill
Simple skill: `open Slate.xcodeproj`. Created using `/skill-creator`. ~5 minutes.

#### prompt skill (major)
Full prompt engineering workflow — the most time-intensive part of this phase.

**5-step workflow**:
1. **Clean & Structure** — reformat user's raw input for clarity
2. **Review** — AskUserQuestion with "Do it" / "What did I say?"
3. **Iterate & Warn** — Claude adds analysis, flags architectural risks
4. **Execute via Subagent** — Task tool with fresh context, main conversation stays lean
5. **Save Prompt File** — `workflows/prompts/<unix-timestamp>.md` with YAML frontmatter

**Rules established**:
- Never execute without explicit "Do it"
- Never recap what was just done
- Stay in flow — each message presents new info or asks for a decision

**Decisions**:
- Frontmatter fields are the index (no separate database): `author`, `project`, `tags`, `conversation_id`, `commit_hash`, `status`
- Commit rules: every commit updates its prompt file's `commit_hash` and `status`
- Created `CLAUDE.md` with commit rules

**Problems**:
- AskUserQuestion doesn't support text input on individual options — settled on predefined choices + "Other"
- Tab-and-type confirmation UI is tool-approval-specific, can't be replicated for custom questions

### Phase 7: Reproducibility Research (`b98cc24c`, ~5 min)

**What**: Investigated whether Nix can reduce Xcode dependency.

**Key findings**:
- Xcode must be *installed* but doesn't need to be *open* for most work
- Nix can manage: XcodeGen version, SwiftLint, SwiftFormat, `xcodes` CLI, build scripts
- Nix cannot manage: Xcode.app, Apple SDKs, provisioning profiles, simulators
- Biggest win: `.gitignore` the `.xcodeproj`, regenerate deterministically from `project.yml`

**Not yet actioned** — research for future DX improvements.

## Architecture Snapshot

```
Slate/
  SlateApp.swift          # @main, sets up ModelContainer
  Models/
    TodoItem.swift        # SwiftData @Model, Priority/TodoType enums
  Views/
    TodoListView.swift    # Main list, add/edit/toggle/reorder
    SettingsView.swift    # Notifications, theme placeholder
  Shared/
    PersistenceConfig.swift  # App group container, schema migration
    NotificationManager.swift
  Theme/
    Theme.swift           # Design tokens: colors, spacing, radius

SlateWidget/
  SlateWidget.swift       # Widget bundle (home + lock screen)
  TodoTimelineProvider.swift
  TodoWidgetView.swift
  ToggleTodoIntent.swift  # Interactive widget action

project.yml              # XcodeGen project definition
```

**Stack**: SwiftUI, SwiftData, WidgetKit, AppIntents, iOS 17+, Swift 5.9, zero external dependencies.

## Developer Patterns Observed

- **Research → spec → build**: 2 hours of research in brainstorming (see [000](000-research-and-ideation.md)) produced a spec that built the entire app in one session. No false starts.
- **Plan then execute**: UI modernization was planned in TodoFlow, refined across 2 sessions, then executed in Slate with a clipboard-pasted plan. Not impulsive.
- **Brand vs domain naming**: Deliberate separation — brand names for user-facing/config, domain names for internal code. Future rebrands stay shallow.
- **Clean breaks over migrations**: Schema v2 nukes the store rather than migrating. Right call for early development.
- **DX investment early**: Built skills and workflow tooling before adding features. The prompt skill alone took ~1.5 hrs — significant for a day-one investment.
- **Scope discipline**: Repeatedly constrained scope ("minimum modern aesthetic", "don't do unnecessary work").

## Open Questions

- Should we `.gitignore` the `.xcodeproj` and regenerate from `project.yml`?
- Add Nix flake with devShell for reproducible tooling (XcodeGen, SwiftLint)?
- When does it make sense to add a test target?
- The `~/TodoFlow` directory is now empty — should it be cleaned up?

## What's Next

This meta documents the v0 build. The app works on device and simulator. Next iterations will add features on top of this foundation, each documented with their own meta entry and linked prompts.
