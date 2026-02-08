# Slate

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
| `Makefile` | `generate`, `build`, `lint`, `clean`, `help` |
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

### App Groups entitlements must be configured when using shared containers

When setting up an iOS app with extensions (e.g. widgets) that share data via App Groups (`FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`), you must add the `com.apple.security.application-groups` entitlement to **every** target's `.entitlements` file. Generating entitlements files or scaffolding a new target does not automatically populate them — they start as empty `<dict/>`. If you write code that references an app group identifier but forget to declare it in the entitlements, the app will crash at runtime with no compile-time warning.

**Critical:** In XcodeGen projects, editing `.entitlements` files directly is not enough — `xcodegen generate` will overwrite them. You must declare entitlement properties in `project.yml` under each target's `entitlements.properties` key. If you only set `entitlements.path` without `properties`, XcodeGen generates an empty `<dict/>`.

**Also critical:** Even with correct entitlements files, App Groups require code signing with a **development team**. Without one configured, the entitlement is silently not applied and `containerURL(forSecurityApplicationGroupIdentifier:)` returns `nil` at runtime — even on the simulator.

**Rule:** Whenever you create or modify code that uses `containerURL(forSecurityApplicationGroupIdentifier:)`, `UserDefaults(suiteName:)`, or any other App Group API:
1. Add the group identifier to `project.yml` under `entitlements.properties` for **every** target that needs it
2. Re-run `xcodegen generate` to regenerate the `.entitlements` files
3. Verify the generated `.entitlements` files actually contain the group identifier
4. **Never `fatalError` on App Group lookup failure** — always provide a graceful fallback (e.g. documents directory) so the app works during unsigned development, with a warning log
