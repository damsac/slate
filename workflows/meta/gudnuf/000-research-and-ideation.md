---
id: "000"
title: "Research & Ideation: What to Build and How"
status: completed
author: gudnuf
project: Slate
tags: [ideation, research, naming, widgetkit, react-native, swift, architecture, ui-mocks]
sessions:
  # Brainstorming era (~/brainstorming)
  - id: 38d5d9ff
    slug: app-concept-mocks-and-naming
    dir: brainstorming
  - id: 8725a390
    slug: widget-feasibility-and-tech-stack
    dir: brainstorming
prompts: []
created: "2026-02-07T23:25:00Z"
updated: "2026-02-08T01:36:00Z"
---

# 000: Research & Ideation — What to Build and How

## Context

Before any project directory existed, the developer spent ~2 hours in `~/brainstorming` researching feasibility, exploring the design space, and making foundational technology decisions. No code was written. The output was a clear spec, a name, and a ready-to-execute implementation prompt.

## Timeline

### Phase 1: App Concept & UI Mocks (`38d5d9ff`, ~2 hrs)

**What**: Defined the app concept, created UI mocks, designed data models, and chose a name.

**App vision**: A minimalist daily todo list focused on mental clarity — quickly dump tasks, check them off from widgets and notifications, review at end of day. Not a productivity power tool; a mental offloading tool. The core insight: "I don't want to think about my todos because the app handles them."

**UI mocks created** (7 screens, [view mocks](assets/000/index.html)):
- Today View (light/dark) with progress ring
- Morning Planning screen with upcoming deadlines
- Backlog with "+ Today" buttons
- Add Task bottom sheet
- End of Day Review
- Home Screen Widgets (checklist, progress ring, "next up")
- Notification examples

**Data model designed** (3-table architecture):
- `User` — notification preferences, timezone
- `Task` — master list (backlog + recurring templates)
- `DailyTask` — concrete instances per day

**Naming journey**: Extensive brainstorm across multiple rounds:
- Round 1: Slate, Cairn, Three, Docket, Nudge, Pare, Etch, Dawn
- Round 2: Rasa, Still, Clear, Exhale (clarity concept)
- Round 3: Offslate, Pour, Shed, Rundown, Sluice (braindump direction)
- Round 4: Lucid, Headroom, Still, Sorted, Tabula (clarity of mind)

**Decision**: "Slate" — clean slate metaphor. Simple, modern, memorable.

### Phase 2: Widget Feasibility & Tech Stack (`8725a390`, ~43 min)

**What**: Validated that interactive home screen widgets are technically possible, then chose the implementation stack.

**Key research questions answered**:

| Question | Answer |
|----------|--------|
| Can iOS widgets have interactive checkboxes? | Yes — iOS 17+ with `Button`/`Toggle` + `AppIntent` |
| Can widgets share data with the app? | Yes — App Groups (shared SQLite/UserDefaults) |
| Do widgets update in real-time? | No — timeline-based with manual `reloadAllTimelines()` |

**React Native vs Swift evaluation**:
- Initially considered React Native (developer's familiar stack)
- Discovery: widget extension must be native Swift/SwiftUI regardless — no JavaScript in widgets
- Hybrid approach explored: RN app + native widget with data bridge via shared UserDefaults
- Complexity assessment: two UI layers, bidirectional state sync, native bridge modules
- **Decision: full native Swift/SwiftUI**. Tightest widget integration, no bridge complexity, single language.

**Architecture decisions locked in**:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| UI framework | SwiftUI | Native, declarative, required for widgets |
| Persistence | SwiftData | On-device SQLite, no remote DB needed, App Group compatible |
| Widget interactivity | AppIntent (iOS 17+) | Direct checkbox toggles on home screen |
| Data sharing | App Group container | Single SQLite file, both targets access it |
| Remote DB/auth | None (MVP) | Offline-first, add CloudKit later if needed |

**Future feature explored**: AI todo extraction — record voice → on-device Speech/Whisper transcription → Claude API extracts todos. Decided to defer to Phase 2.

**Final output**: A complete implementation prompt specifying tech stack, project structure, two targets (app + widget), data model, App Group config, and MVP scope. This prompt was used to kick off the actual build.

## Developer Patterns Observed

- **Research before code**: Spent 2+ hours on feasibility, design, and architecture before writing a single line. The implementation prompt was thorough enough to build the entire app in one session.
- **Familiar → optimal stack pivot**: Started with React Native (comfort zone), pivoted to Swift after understanding the constraints. Didn't force a familiar tool into an unfitting problem.
- **Emotional product thinking**: The naming discussion revealed the app's core value proposition isn't task management — it's peace of mind. "Clarity of mind" was the guiding filter for the name.
- **Scope gating**: Explicitly deferred AI features to Phase 2. Kept MVP to core todo + widgets.
- **Visual-first design**: Created 7 UI mocks before any architecture decisions. Understood what to build before figuring out how.

## Artifacts

- [UI mocks](assets/000/index.html) — 7 screens (today view, planning, backlog, add task, review, widgets, notifications)
- [Data models](assets/000/data-models.ts) — 3-table architecture (User, Task, DailyTask)
- Implementation prompt: generated at end of `8725a390`, used to start the build

## What Happened Next

The implementation prompt from Phase 2 was fed directly into a new session (`1b07722a` in home dir) where the entire app was built, deployed to simulator and device, and documented — all in one ~3 hour session. See [001-initial-build.md](001-initial-build.md).
