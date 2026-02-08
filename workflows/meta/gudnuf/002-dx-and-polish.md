---
id: "002"
title: "DX Infrastructure & UI Polish"
status: active
author: gudnuf
project: Slate
tags: [nix, devshell, xcodegen, git-hooks, dx, ui, mermaid, pr-workflow, meta-workflow, skills]
previous: "001"
sessions:
  - id: d1b72b62
    slug: meta-workflow-system-creation
    dir: Slate
  - id: 07c77c41
    slug: mermaid-mcp-setup
    dir: Slate
  - id: fb88e119
    slug: ui-modernization
    dir: Slate
  - id: d590cc37
    slug: mermaid-mcp-debugging
    dir: Slate
  - id: e91d4419
    slug: prompt-file-backlinks
    dir: Slate
  - id: b98cc24c
    slug: nix-dev-environment-planning
    dir: Slate
  - id: 26df1cf0
    slug: initial-commit-pr-and-draft-pr-skill
    dir: Slate
  - id: cce96fe0
    slug: meta-workflow-triage
    dir: Slate
  - id: 13371d7b
    slug: architecture-diagram-attempt
    dir: Slate
  - id: fd8ddb73
    slug: nix-dev-environment-implementation
    dir: Slate
prompts:
  - workflows/prompts/1770536464.md
  - workflows/prompts/1770539531.md
created: "2026-02-08T05:33:00Z"
updated: "2026-02-08T08:52:00Z"
---

# 002: DX Infrastructure & UI Polish

## Context

After the v0 app was built and documented in [001-initial-build](001-initial-build.md), the focus shifted to two tracks: (1) making the app look like it belongs on iOS 26, and (2) building reproducible developer infrastructure for a second contributor. This also included creating the meta-workflow documentation system, the `/draft-pr` skill, and the first PRs.

## Timeline

### Phase 1: Meta-Workflow System (`d1b72b62`, ~2.2 hrs)

**What**: Created the structured documentation system that this file is part of.

**Built**:
- `workflows/meta/` directory with per-author journal entries
- `/meta-workflow` skill (SKILL.md) — auto-detects author, mines session transcripts via parallel subagents, creates structured markdown
- Two retrospective entries: `000-research-and-ideation.md` (pre-code brainstorming) and `001-initial-build.md` (v0 build through design system)
- `000-template.md` for onboarding new developers
- Moved UI mockups from `~/brainstorming` into `workflows/meta/gudnuf/assets/000/`

**Decisions**:
- **Per-author subdirectories** over flat numbering — each dev maintains their own sequence
- **Git config for author** — `git config user.name` rather than hardcoding
- **Scope to current project only** — initially searched across all project dirs, removed that to avoid noise
- **Meta = narrative, prompts = receipts** — bidirectional linking between the two

**Problems**: 2.6MB transcript too large to read directly — used `jq` + chunked reads. JSON-escaped quotes broke initial grep patterns — switched to unquoted keywords.

### Phase 2: Mermaid MCP Server (`07c77c41` + `d590cc37`, ~1 hr)

**What**: Researched, audited, and installed a Mermaid diagram rendering MCP server for Claude Code.

**Research**: Compared 4 servers (veelenga/claude-mermaid, hustcc, peng-shawn, Narasimhaponnada). Selected `veelenga/claude-mermaid` — purpose-built for Claude Code, live WebSocket reload, minimal deps.

**Security audit**: Full source code review of v1.4.0. Two medium-severity findings (binds 0.0.0.0, unvalidated /view/ route) — low practical risk for single-user dev.

**Decisions**:
- **`bunx` over Nix** for execution — developer directed simpler approach
- **Project-level `.mcp.json`** over user-level config — scoped to Slate only

**Problems**: MCP server failed in follow-up session — `npx` not in PATH. Debugging revealed command structure issues with `nix run nixpkgs#bunx`.

**Outcome**: Later removed entirely (commit `02fd467`) after the architecture diagram session hit too many rendering dependency issues. The MCP config was deleted rather than left broken.

### Phase 3: UI Modernization (`fb88e119`, ~55 min)

**What**: Fixed the app looking like it was from 2012 — black bars, old keyboard, dated card-based styling.

**Critical discovery**: App was running in iOS legacy compatibility mode due to missing `UILaunchScreen` key in Info.plist. This caused letterboxing and the old keyboard style. One-line fix in `project.yml`.

**Visual changes**:
- Removed 2018-era card backgrounds with rounded rectangles
- Dropped colored priority bars (too rigid)
- Switched to native List styling with clean separators
- Used SwiftUI defaults (list row insets, separators) instead of custom overrides

**Animation rabbit hole (~15 min, abandoned)**: Tried 4 approaches to fix input field flashing on todo submission — animate insertion, different transactions, isolate addSection. Each attempt deployed to simulator for testing. None worked satisfactorily. Developer said "just revert." Minor visual issue not worth brittle code.

**Pattern**: Developer had low tolerance for over-engineering. Preferred removing custom styling (return to native) over adding more. Willing to live with minor flashing rather than add complexity.

### Phase 4: Prompt File Maintenance (`e91d4419`, ~5 min)

**What**: Updated `workflows/prompts/1770529524.md` to add backlink to the prompt skill it helped create.

### Phase 5: Nix Dev Environment (`b98cc24c` + `fd8ddb73`, ~5 hrs)

**What**: Designed and implemented a reproducible Nix-based dev environment for a second developer joining.

#### Planning (`b98cc24c`, ~3 hrs)

**Key debate — XcodeGen**: Agent initially recommended dropping `project.yml` for a small team. Developer pushed: "lets take the most reproducible route even if it means extra steps." Decision: keep XcodeGen, gitignore `.xcodeproj/` entirely, regenerate deterministically.

**Architecture decided**:

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Tool pinning | Nix flake devShell | Reproducible versions of xcodegen, swiftlint, xcbeautify, gnumake |
| Shell activation | direnv + `.envrc` | Auto-activates on `cd` into project |
| Per-dev config | `project.local.yml` (gitignored) | `DEVELOPMENT_TEAM` per developer, merged via XcodeGen `include:` |
| Build workflow | Makefile | `generate` (with entitlements validation), `build`, `lint`, `clean` |
| Git hooks | Nix store scripts | Pre-commit: lint + validate entitlements. Post-merge: regenerate after pull |

**Bug found during planning**: Setup skill referenced wrong App Group identifier (`group.com.slate.shared` vs `group.com.damsac.slate.shared`). Flagged for correction.

#### Implementation (`fd8ddb73`, ~1 hr)

**Created**: `flake.nix`, `.envrc`, `project.local.yml.template`, `Makefile`
**Modified**: `project.yml`, `.gitignore`, setup skill, README, CLAUDE.md, TODO.md
**Deleted from index**: `Slate.xcodeproj/` (now regenerated, never committed)

**Problems**:
- `nix flake check` failed — `flake.nix` not staged (Nix requires git-tracked files)
- `.envrc` wouldn't stage — globally gitignored in user's `~/.config/git/ignore`. Fixed with `git add -f`
- XcodeGen doesn't support `optional: true` on includes — Makefile `touch`es empty `project.local.yml` as fallback
- Git commit failed on SSH key signing (hardware key timeout)

**Commit**: `5c4eb8e feat: Nix-based reproducible dev environment with git hooks`

### Phase 6: First PRs & Draft-PR Skill (`26df1cf0`, ~2 hrs)

**What**: Created the first git repository, initial commit, two PRs, and extracted the PR creation process into a reusable `/draft-pr` skill.

**Repo setup**:
- Empty initial commit on `master` (developer preference over `main`)
- Feature branch `feat/initial-setup` with all v0 code
- PR #1: "feat: Slate v0 — app, widgets, tooling" — information-dense description teaching reviewers about the codebase

**PR description iterations (3 rounds)**:
1. Standard PR with file list — too code-focused
2. Shifted to workflows/skills focus — better but too directive
3. Final: step-by-step learning experience — "here's WHY you should skim these files"

**Key tension**: How verbose should PRs be? Converged on "density over length" — tables, diagrams, and links instead of prose.

**Skill created**: `.claude/skills/draft-pr/SKILL.md` — analyzes changes + workflow docs + meta entries to produce PRs that teach reviewers. Uses `gh pr create --web` so humans review the form before submitting.

**Insight**: Realized code quality (catching bugs) and communication (explaining changes) are separate concerns. Added `/review-changes` to TODO as a future pre-PR skill.

**Commits**:
- `02fd467 remove mermaid mcp`
- `0828638 update meta-workflow skill to not look at other projects`
- `5b409b0 dx: add /draft-pr skill`

### Phase 7: Architecture Diagram Attempt (`13371d7b`, ~8 min)

**What**: Tried to generate a Mermaid architecture diagram. Mermaid MCP tool failed (`npx` not in PATH). Attempted `nix shell` workaround — hit Puppeteer/Chromium dependency issues. Wrote diagram source to `docs/architecture.mmd`, then developer asked to remove everything. Cleaned up completely. No persistent changes.

**Outcome**: Confirmed that Mermaid rendering requires heavy browser dependencies not worth managing. The MCP server was already removed in Phase 6.

### Phase 8: Meta-Workflow Triage (`cce96fe0`, ~17 min)

**What**: Invoked `/meta-workflow` to identify undocumented sessions. Listed 7 sessions with timestamps and one-sentence descriptions. Flagged 2 as trivial. Established scope for this entry (002).

## Developer Patterns Observed

- **Reproducibility over simplicity**: When given the choice, explicitly chose the harder path ("most reproducible route even if it means extra steps"). XcodeGen, Nix flakes, and gitignored `.xcodeproj` all add ceremony but remove ambiguity.
- **Remove, don't add**: UI modernization was mostly *deleting* custom styling. When animation fixes didn't work cleanly, reverted rather than adding complexity. Mermaid MCP was removed rather than left half-working.
- **Skills as workflow capture**: Every non-trivial repeated process got extracted into a skill — meta-workflow, draft-pr, prompt. DX investment before features.
- **Density over length**: PR descriptions, meta entries, and commit messages optimized for skimmability. Tables and links over prose.
- **Fail fast on silent failures**: Makefile validates entitlements after every `xcodegen generate`. CLAUDE.md documents the App Group entitlement footgun. Setup skill warns about unsigned development fallbacks.

## Artifacts

- PR #1: [feat: Slate v0](https://github.com/damsac/slate/pull/1) — initial setup
- PR #2: draft-pr skill (branch `dx/draft-pr-skill`)
- [Prompt: initial commit/PR](../../workflows/prompts/1770536464.md)
- [Prompt: Nix dev environment](../../workflows/prompts/1770539531.md)

## Open Questions

- Mermaid diagram rendering — is there a lighter-weight solution than browser-based rendering?
- `/review-changes` skill — when to build it? What should code quality checks look like?
- CI/CD — now that there's a Makefile and Nix flake, GitHub Actions could run `make lint` and `make build`
- Should the meta-workflow skill auto-link prompt files, or is manual linking sufficient?

## What's Next

The app has a working design system, reproducible dev environment, and documented workflows. The next iteration should focus on **app features** — the todo experience itself. The DX foundation is solid enough to support a second developer and iterate quickly.
