---
id: "003"
title: "Documentation, CI/CD Foundation & Second Developer"
status: active
author: gudnuf
project: Slate
tags: [documentation, ci, github-actions, pr-review, skills, onboarding, readme, claude-code-action]
previous: "002"
sessions:
  - id: fcd05f8e
    slug: open-xcode-and-prompt-skills
    dir: Slate
  - id: b173c239
    slug: theme-design-system
    dir: Slate
  - id: a28a9db4
    slug: meta-workflow-002-writing
    dir: Slate
  - id: 2c2fdf34
    slug: claude-md-philosophy
    dir: Slate
  - id: b4dfd7ae
    slug: readme-slash-commands
    dir: Slate
  - id: 7f0e6fa9
    slug: draft-pr-skill-discovery
    dir: Slate
  - id: a9fed7dd
    slug: readme-audit-and-gaps
    dir: Slate
  - id: b6c1c610
    slug: pr-review-workflow-design
    dir: Slate
prompts: []
created: "2026-02-09T00:00:00Z"
updated: "2026-02-09T01:00:00Z"
---

# 003: Documentation, CI/CD Foundation & Second Developer

## Context

Entry [002](002-dx-and-polish.md) established the DX infrastructure (Nix devShell, git hooks, Makefile). This entry covers what happened next: polishing documentation for a second developer (Isaac), creating new skills, auditing the README against actual project conventions, and designing the automated PR review system. Isaac's [onboarding](../IsaacMenge/000-onboarding.md) and [environment setup](../IsaacMenge/001-environment-setup.md) entries happened during this same period — the documentation work here was partly in response to friction he encountered.

## Timeline

### Phase 1: Skill Creation (`fcd05f8e`, ~55 min)

**What**: Created two new skills using `/skill-creator`.

**`/open-xcode`** — Opens the Slate Xcode project. Went through 4 iterations refining the SKILL.md. Simple utility skill but exercised the skill-creator workflow.

**`/prompt`** — The prompt engineering skill that became central to the workflow. Defines the "Do it" gate: Claude never executes without explicit approval. Manages prompt file lifecycle (clean up input -> present -> execute in subagent -> save receipt).

**Pattern**: Both skills created in one session. The `/prompt` skill was the more important one — it formalized the idea that every implementation starts with a human-reviewed prompt, not ad-hoc instructions.

### Phase 2: Theme Design System (`b173c239`, ~45 min)

**What**: Created `Theme.swift` with centralized design tokens and refactored all views to use them.

**Built**:
- `Theme` enum with static properties: colors (using system colors for automatic dark mode), spacing constants, corner radii, priority color helper
- Refactored `TodoListView`, `TodoRow`, `EditTodoView`, `TodoWidgetView` to reference `Theme.*` instead of hardcoded values
- Removed unused `Priority.color` property

**Critical fix**: Dark mode had uncolored safe area edges. Fixed with `.scrollContentBackground(.hidden)` + `.background(Theme.background.ignoresSafeArea())` — two lines to fill the entire screen edge-to-edge.

**Decision**: Used system colors (`Color.accentColor`, `Color(.systemBackground)`) over explicit hex values. Automatic light/dark mode support without manual color sets.

### Phase 3: Meta Documentation (`a28a9db4`, ~1 hr)

**What**: Ran `/meta-workflow` to produce entry 002. Spawned 13 parallel session miners to extract summaries from the full session history. This was the first large-scale use of the session-miner subagent pattern.

**Problems**: Several session files exceeded direct read limits (>900KB). Used subagent parallelization with chunked reads and grep-based extraction as fallbacks. Coordinating 13+ concurrent mining tasks required careful orchestration.

### Phase 4: CLAUDE.md Philosophy & TODOs (`2c2fdf34`, ~5 min)

**What**: Added the "Philosophy" section to the top of CLAUDE.md, defining two key principles:
1. Skills are written for humans, used by Claude
2. CLAUDE.md is a living document, primarily for Claude, tracked by humans

Also added a TODO for code signing on real devices — identified that unsigned builds silently skip App Group entitlements, causing `containerURL` to return `nil`. Cross-referenced the CLAUDE.md learning.

### Phase 5: README & Slash Command Updates (`b4dfd7ae`, ~20 min)

**What**: Updated README.md to document `/prompt` as a slash command alongside the natural language trigger. Updated the prompt skill description for consistency.

**Decision**: Slash commands (`/prompt`) are the primary invocation method; natural language ("make a prompt") is secondary. README command table updated to reflect this.

### Phase 6: Draft-PR Skill Discovery (`7f0e6fa9`, ~10 min)

**What**: Tried to use `/draft-pr` to update PR #1's description. Discovered the skill existed on the `dx/draft-pr-skill` branch, not in the current branch.

**Outcome**: Short session — confirmed the skill was on a separate branch and needed to be merged before it could be used from `feat/initial-setup`.

### Phase 7: README Audit (`a9fed7dd`, ~30 min)

**What**: Comprehensive audit of README against project conventions. Used a deep exploration agent to map every documented concept across CLAUDE.md, skills, meta entries, and infrastructure files.

**Findings — 13 major documentation gaps**:

| Gap | Impact |
|-----|--------|
| `/draft-pr` missing from commands table | Core command invisible |
| Commit workflow with prompt files | Unique convention nobody would guess |
| Git hooks behavior | Devs hit these immediately |
| Prompt library system | Central to work tracking |
| Developer journals structure | Per-author workflow |
| Branch naming conventions | `feat/*`, `dx/*` patterns |
| Per-developer config details | `project.local.yml` purpose unclear |
| Nix/direnv rationale | Ceremony feels arbitrary without context |
| App Group architecture | Critical for widget data sharing |
| Architecture decisions | Why Swift over RN, why XcodeGen |
| Skill discoverability | How to find and create skills |
| Claude Code integration | What it means in practice |
| Troubleshooting depth | Only brief section in README |

**Response to Isaac's onboarding**: Several gaps directly map to friction Isaac documented — `direnv allow` timing ([001-environment-setup](../IsaacMenge/001-environment-setup.md) Phase 2), bundle ID ownership (Phase 6), and the setup skill not explaining what happens in each phase. The audit was partly motivated by making onboarding smoother.

### Phase 8: PR Review Workflow Design (`b6c1c610`, ~1 hr)

**What**: Designed an automated Claude-powered PR review system for GitHub Actions. Researched the `anthropics/claude-code-action` repository for reference architecture.

**Research findings**:
- `claude-code-action` uses an `.claude/agents/` directory with specialized reviewer agents (code-quality, security, documentation-accuracy, performance, test-coverage)
- Each agent is a markdown file with focused review instructions
- Agents are referenced from GitHub Actions workflows

**Architecture decided**:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Fix delivery | Push directly to PR branch | Simpler than follow-up PRs, clearer diff |
| Fork PRs | Comment-only (no push) | GitHub security boundaries prevent branch push on forks |
| Out-of-scope findings | Create GitHub issues | Don't block PR for unrelated problems |
| Agent structure | Specialized reviewers | Mirrors anthropic's own pattern — focused scope per agent |

**Connection to Isaac's experience**: Isaac's [001-environment-setup](../IsaacMenge/001-environment-setup.md) documented the Xcode 26 linker issue breaking `make build`. An automated CI/CD pipeline would catch these compatibility issues before they surprise new developers. The PR review system was partly motivated by having a second contributor whose environment differs from the original.

## Response to Isaac's Journal Entries

Isaac's [000-onboarding](../IsaacMenge/000-onboarding.md) made several observations worth responding to:

**"The meta/prompt workflow is the interesting part, not the todo app itself"** — Exactly right. The app is a vehicle for the workflow system. The README audit (Phase 7) was partly about making this more visible — the README focused too much on the app and not enough on the collaboration system.

**"Skills as human-readable, Claude-executable docs is a clean abstraction"** — This observation directly inspired the CLAUDE.md Philosophy section (Phase 4). The framing "written for humans, used by Claude" became the canonical way to describe skills.

**"The PR description references steps but skips Step 5"** — Caught. The draft-PR skill exploration (Phase 6) was about improving these descriptions, but the skill wasn't yet available on the main branch.

**"The relationship between meta entries and prompt files wasn't immediately clear"** — The README audit (Phase 7) flagged this exact gap. The prompt library system and its lifecycle (status: executed -> committed) wasn't documented in README at all.

From Isaac's [001-environment-setup](../IsaacMenge/001-environment-setup.md):

**Xcode 26 linker issue (`-Xlinker` incompatibility)** — This is a significant finding. `make build` is broken on Xcode 26 while Xcode GUI builds work fine. This affects CI/CD planning (Phase 8) — any GitHub Actions pipeline needs to either pin Xcode versions or use the `-ld_classic` flag.

**Bundle ID ownership** — Free Apple accounts can't use another developer's bundle IDs. The `project.local.yml` pattern handles `DEVELOPMENT_TEAM` but not bundle IDs. Isaac's suggestion to support bundle ID overrides is worth implementing.

**"direnv allow is needed before tools work, and a fresh terminal/Claude session is required after"** — This was flagged in the README audit as a gap. The setup skill documents it but README doesn't.

## Developer Patterns Observed

- **Documentation follows friction**: The README audit happened after Isaac's onboarding exposed real gaps. Documentation written before users arrive is always incomplete — the best time to fix docs is right after someone gets stuck.
- **Skills beget skills**: Creating `/open-xcode` and `/prompt` in one session showed the skill-creator workflow is fast enough to capture utility skills opportunistically rather than waiting until they're "important enough."
- **Audit before building**: The README audit (Phase 7) identified 13 gaps before writing a single line of documentation. Research-first pattern from 000 applied to docs.
- **CI responds to team growth**: The PR review workflow (Phase 8) was motivated by having a second contributor. Solo developers don't need automated review; teams do.

## Open Questions

- How to fix `make build` for Xcode 26? (from Isaac's findings — `-ld_classic` flag, XcodeGen update, or accept GUI-only builds)
- Should bundle ID overrides be supported in `project.local.yml`?
- When to merge the README improvements identified in the audit?
- Which specialized review agents to implement first? (code-quality and workflow-accuracy seem highest value)
- Should the session-miner agent be improved to handle >1MB transcripts more reliably?

## What's Next

The documentation gaps are mapped. The CI/CD architecture is designed. Isaac is set up and contributing. The next phase should:
1. Merge README improvements from the audit
2. Implement the PR review GitHub Action with at least code-quality and workflow-accuracy agents
3. Address the Xcode 26 build compatibility issue
4. Start building actual app features — the DX foundation is mature enough
