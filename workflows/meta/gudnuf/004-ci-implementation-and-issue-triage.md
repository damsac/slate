---
id: "004"
title: "CI/CD Implementation & Refinement"
status: active
author: gudnuf
project: Slate
tags: [ci, github-actions, testing, pr-review, issues, environment, app-group, permissions]
previous: "003"
sessions:
  - id: 5ef2e65c
    slug: app-group-build-setting
    dir: Slate
  - id: 284a51ea
    slug: console-warnings-issue
    dir: Slate
  - id: 6052493e
    slug: onboarding-friction-issue
    dir: Slate
  - id: 85aefd9b
    slug: environment-enforcement
    dir: Slate
  - id: 7d842ab6
    slug: pr-review-implementation
    dir: Slate
  - id: 7766f205
    slug: github-actions-design
    dir: Slate
  - id: d5b3502f
    slug: test-strategy-and-ci-gate
    dir: Slate
  - id: 8d7ae622
    slug: unit-tests-and-ci-gate
    dir: Slate
  - id: 7d0d18d4
    slug: issue-to-prompt-traceability
    dir: Slate
  - id: fbf115ed
    slug: linux-ci-fix
    dir: Slate
  - id: da32fc0d
    slug: claude-code-ci-integration
    dir: Slate
  - id: 443bdf5c
    slug: ci-environment-config-fixes
    dir: Slate
  - id: eea792e9
    slug: pr14-migration-instructions
    dir: Slate
prompts: []
created: "2026-02-09T02:00:00Z"
updated: "2026-02-09T02:45:00Z"
---

# 004: CI/CD Implementation & Refinement

## Context

Entry [003](003-docs-ci-and-onboarding.md) designed the CI/CD architecture and documented gaps. This entry covers the implementation burst that followed: building the test gate, automated PR review, environment enforcement, and issue triage — then refining it all until it actually worked cross-platform. All 13 sessions happened within a ~5 hour window on the same afternoon.

## Timeline

### App Group Build Setting Refactor (`5ef2e65c`)

Replaced the hardcoded App Group identifier in `PersistenceConfig.swift` with a build-setting-driven value read from Info.plist via XcodeGen.

**Key decision**: `fatalError` if the build setting is completely absent (catches developer misconfiguration) but graceful fallback if the App Group container is unavailable at runtime (handles unsigned/simulator builds). Missing config = developer error; missing entitlements = expected state.

**Commit**: `9b19b06 refactor: replace hardcoded App Group ID with build setting variable`

### Issue Triage from Onboarding (`284a51ea`, `6052493e`)

Created two categorized GitHub issues from real developer friction:

**[Issue #5](https://github.com/damsac/slate/issues/5) — Console warnings**: Diagnosed 6 Xcode warnings when adding todos. 3 actionable (App Group guard, toolbar Spacer, frame sizing), 3 system noise (Apple UIKit internals, simulator-only). Documented which to fix vs. ignore.

**[Issue #6](https://github.com/damsac/slate/issues/6) — Onboarding friction**: Distilled 5 problems from Isaac's PR #4 journal entries: `make build` broken on Xcode 26 (new linker), no bundle ID overrides, direnv not active for Claude Code, no disk space check, Xcode version undocumented. Issues from real friction, not speculation.

### Environment Enforcement (`85aefd9b`)

Added a `shellHook` in `flake.nix` that checks `xcodebuild -version` on shell activation and warns if below Xcode 26.

**Decision**: Warning, not error — allows flexibility while encouraging standardization. Catches issues before build attempts fail.

**Commit**: `f8b6a06 feat: enforce development environment requirements (#14)`

### PR Review System (`7d842ab6`)

Implemented the automated PR review designed in 003:

| File | Purpose |
|------|---------|
| `.claude/agents/code-reviewer.md` | Read-only agent: App Group safety, dead code, duplication |
| `.claude/agents/workflow-reviewer.md` | Read-only agent: prompt/meta file integrity |
| `.claude/commands/review-pr.md` | Orchestrator: dispatches agents, pushes fixes, posts comments |
| `.github/workflows/claude-review.yml` | GitHub Actions trigger on PR open/push |

**Architecture**: Dual-agent with write-only orchestrator. Agents observe via `Bash(git diff:*)` and `Bash(git log:*)`; only the orchestrator can edit/push/comment. Fork detection downgrades to comment-only mode.

### Test Strategy, Implementation & CI Gate (`7766f205`, `d5b3502f`, `8d7ae622`)

Designed and built the testing infrastructure across three sessions:

**Test scope**: Pure-logic components only — `TodoItemTests`, `ThemeTests`, `PersistenceConfigTests` (~40 assertions). No SwiftData or UI tests.

**Infrastructure**: XcodeGen test target in `project.yml`, `make test` in Makefile, `ci.yml` on `macos-latest`. Review job uses `needs: [test]` to gate behind passing tests.

**Key decision — simplify CI**: Initial plan included Nix flake modifications and a parameterized `nix-ci` action. Dropped in favor of `brew install xcodegen xcbeautify` on the macOS runner — simpler, cheaper, faster.

**Gotcha — exit code propagation**: `xcodebuild test | xcbeautify` always exits 0 even when tests fail (pipe hides exit code). Fixed with `set -o pipefail`.

**Gotcha — pre-existing violations**: SwiftLint violations blocked the initial commit. Fixed all violations in a separate commit first (`c1ad78d`), then added test infrastructure.

### Issue-to-Prompt Traceability (`7d0d18d4`)

Added `issue: <number>` field to prompt file frontmatter so prompts and GitHub issues link bidirectionally.

**Commit**: `9103971 feat: add issue field to prompt frontmatter for traceability` (PR #12)

### Cross-Platform CI Fixes (`fbf115ed`, `da32fc0d`)

**Linux fix**: Removed Nix setup action from `claude.yml` and `claude-review.yml` (leftover from the abandoned Nix CI approach). Made SwiftLint Darwin-conditional in `flake.nix` via `lib.optionals stdenv.isDarwin`. Tests are the quality gate; SwiftLint is a dev-time aid.

**Claude Code integration fix**: Workflows had no system prompt (Claude ran with defaults, not project instructions), read-only permissions (couldn't commit or comment), and no agent access. Fixed by adding `--system-prompt-file` args, upgrading to write permissions, and adding tool allowlist.

**Principle**: CI configuration should be explicit, not reliant on defaults. Defaults change; explicit configuration is reviewable and stable.

### Entitlements Validation Fix (`443bdf5c`, `eea792e9`)

The Makefile's post-generate validation still checked for the literal App Group string after Phase 1 switched to a build setting variable. Updated to check for `APP_GROUP_IDENTIFIER` variable presence instead of a specific value — validates structure, not content.

Added migration instructions to PR #14 for developers with modified bundle IDs.

**Commits**: `5babaed`, `88fc027` (PR #14)

## PRs Merged

| PR | What |
|----|------|
| #1 | Original app + DX infrastructure |
| #3 | Nix CI environment for Claude Code |
| #4 | Isaac's journal entries |
| #7 | Automated PR review system |
| #12 | Issue-to-prompt traceability |
| #13 | Unit tests + CI test gate |
| #14 | Variable-based entitlements validation |

## Patterns

- **Design then implement in one day**: 003 designed the CI architecture; this entry implemented it within hours. Design-first meant implementation was focused because decisions were already made.
- **Issues from empathy, not abstraction**: Issues #5 and #6 came from reading another developer's actual experience, not from imagining what might go wrong.
- **Simplify mid-flight**: Test strategy started as a 10-file Nix-heavy plan and ended as a 6-file brew-based approach. Recognizing when infrastructure complexity exceeds its value is as important as the initial design.
- **Variable-based validation over literal checks**: When validating generated code, check for structure (variable presence) rather than content (specific value). Resilient to per-developer customization.
- **Platform-aware CI**: Tools should only be required where they can run. Graceful degradation via `lib.optionals stdenv.isDarwin`.
- **Migration docs for breaking changes**: When a PR changes developer workflow, document the migration path in the PR description.

## Open Questions

- Issue #5: When to fix the 3 actionable console warnings?
- Issue #6: Bundle ID prefix override in `project.local.yml` — cleanest way across project.yml, Makefile, and PersistenceConfig?
- Should SwiftLint return to CI as a parallel lint job, or stay dev-time only?
- Issue-to-prompt linking is one-directional (prompt → issue). Should there be a reciprocal mechanism?

## What's Next

The CI pipeline is operational: tests gate PRs, Claude reviews automatically, environment enforcement is active. Remaining:
1. Fix 3 actionable console warnings (issue #5)
2. Implement bundle ID overrides (issue #6)
3. Ship app features — infrastructure is mature enough for iterative development
