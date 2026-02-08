# Slate

## Philosophy

**Skills** (`~/.claude/skills/`) are written for humans, used by Claude. They document workflows, conventions, and domain knowledge in a way developers can read, review, and version-control — but their primary consumer at runtime is Claude.

**CLAUDE.md** is a living document, primarily read by Claude to avoid repeating mistakes and to follow project conventions. It should be kept iterative — updated as lessons are learned — and tracked in version control so humans can review what Claude "knows" about the project.

## Commit Rules

When committing code changes, check `workflows/prompts/` for any prompt files related to the current work:
- Update the `commit_hash` field in frontmatter with the commit SHA
- Update `status` from `executed` to `committed`
- Fill out the `Result` section (outcome, approach taken, deviations, or `discarded`)
- Stage the prompt file updates alongside the code changes in the same commit

## Dev Environment

Dev tools are provided by a Nix flake (`flake.nix`) and auto-activated via direnv (`.envrc`). Key files:

| File | Purpose |
|------|---------|
| `flake.nix` | Pins xcodegen, swiftlint, xcbeautify, gnumake |
| `.envrc` | `use flake` — direnv activates the devShell |
| `Makefile` | `generate`, `build`, `test`, `lint`, `clean`, `help` |
| `project.local.yml` | Per-developer settings (gitignored) — copy from `project.local.yml.template` |
| `project.yml` | XcodeGen spec — includes `project.local.yml` when present |

**Rule:** Always use `make generate` instead of bare `xcodegen generate`. The Makefile target validates that both `.entitlements` files contain the App Group identifier after generation.

**Rule:** `DEVELOPMENT_TEAM` is per-developer via `project.local.yml`, not in `project.yml`. Never hardcode a team ID in committed files.

**Rule:** `Slate.xcodeproj/` is gitignored — it's regenerated from `project.yml` by `make generate`. Never commit it.

### Git Hooks (installed automatically by devShell)

- **pre-commit**: If `project.yml` is staged, regenerates xcodeproj and validates entitlements. Runs SwiftLint `--strict` on staged `.swift` files (blocks commit on errors).
- **post-merge**: If `project.yml` changed after pull, runs `make generate`. If `flake.nix`/`flake.lock` changed, prints a reminder to `direnv reload`.

Hooks are Nix store paths symlinked into `.git/hooks/` — they update automatically when `flake.nix` changes and the shell is re-entered.

## Learnings

### App Groups + XcodeGen

When touching App Group APIs (`containerURL(forSecurityApplicationGroupIdentifier:)`, `UserDefaults(suiteName:)`, etc.):
1. Declare the group in `project.yml` under `entitlements.properties` for **every** target — `entitlements.path` alone produces an empty `<dict/>`
2. Run `make generate` and verify the `.entitlements` files contain the identifier
3. Never `fatalError` on lookup failure — fallback gracefully (documents dir) since unsigned builds silently skip entitlements
