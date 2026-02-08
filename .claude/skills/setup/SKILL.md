---
name: setup
description: Interactive developer environment setup for the Slate iOS project. Use when a new developer needs to onboard, when setting up a new machine, or when someone runs /setup. Walks through system checks, project generation, simulator build, physical device deployment, and widget verification step-by-step.
---

# Slate Developer Setup

Interactive walkthrough to get a new developer from zero to a working Slate build on simulator and real iPhone.

## Rules

- **Check for dev shell tools first** — if `xcodegen`, `swiftlint`, or `make` aren't on PATH, instruct the developer to run `direnv allow` in the project directory, restart their shell, and re-launch Claude Code
- **Ask before reading files outside `~/Slate/`** — explain why.
- **Ask before installing system packages** — present what and why, let the dev approve.
- **Never run destructive commands** without explicit approval.
- **One phase at a time** — confirm each passes before moving on.
- **Report results as checklists** after each phase.

## Phase 0: Environment Check

Before starting, verify the dev shell is active:

1. Check if `xcodegen` is on PATH: `which xcodegen`
2. If not found:
   - Tell the developer: "The Nix dev shell is not active. Please run `direnv allow` in the project directory, restart your shell, and re-launch Claude Code"
   - Exit the skill — wait for the developer to restart with the dev shell active

## Phase 1: System Requirements

Check each, report pass/fail:

1. `sw_vers` — macOS 14+
2. `xcode-select -p` and `xcodebuild -version` — Xcode 26.2+ (required)
3. Xcode license — `sudo xcodebuild -license status` (ask before sudo). If not accepted: `sudo xcodebuild -license accept`
4. Nix — `nix --version`. If missing: `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh`
5. direnv — `direnv --version`. If missing: install via Nix or system package manager, add shell hook.
6. `git --version`

Fix gaps with dev approval before continuing.

## Phase 2: Dev Shell Activation

1. `cd ~/Slate && direnv allow` — activates the Nix devShell
2. Verify tools on PATH: `which xcodegen swiftlint xcbeautify make`
3. If direnv isn't hooked into shell, guide the dev to add the hook (`eval "$(direnv hook zsh)"` or equivalent)
4. **Important:** The Claude Code session that ran Phase 1 may not have the dev shell tools on its PATH. Tell the dev to:
   - Exit the current session (`/exit` or Ctrl+C)
   - Open a new terminal tab (so direnv re-activates the shell environment)
   - Run `claude --resume` and pick this conversation from the list to continue with dev shell tools available

## Phase 3: Simulators

1. `xcrun simctl list runtimes` — need iOS 17+
2. `xcrun simctl list devices available` — need an iPhone simulator
3. No runtime → tell dev: Xcode → Settings → Platforms → download iOS 17+
4. No device → `xcrun simctl create "iPhone 16" com.apple.CoreSimulator.SimDeviceType.iPhone-16 <runtime-id>`

## Phase 4: Configuration and Build

1. Check if `project.local.yml` exists. If not:
   - `cp project.local.yml.template project.local.yml`
   - Ask dev for their Apple Development Team ID (Xcode → Settings → Accounts)
   - Edit `project.local.yml`: set `DEVELOPMENT_TEAM` to their Team ID
   - Update bundle IDs if needed (free accounts must use custom bundle IDs)
   - Update `APP_GROUP_IDENTIFIER` to match bundle ID prefix (e.g., `group.com.yourusername.slate.shared`)
2. `make generate` — runs xcodegen and validates entitlements
3. Verify both entitlements files contain the configured App Group identifier
4. `xcodebuild -project Slate.xcodeproj -list` — confirm targets: `Slate`, `TodoWidgetExtension`
5. `make build` — simulator build via xcbeautify
6. On failure, check [troubleshooting.md](references/troubleshooting.md) for common fixes
7. On success: "Simulator build works. Open Slate.xcodeproj, select the simulator, Cmd+R to run."

## Phase 5: Physical Device (Optional)

Ask the dev if they want to set this up. Skip if no.

### 5a: Device Prep
1. iPhone must be iOS 17+ (Settings → General → About)
2. Developer Mode on: Settings → Privacy & Security → Developer Mode → toggle (requires restart)
3. Connect USB, unlock, tap "Trust This Computer"
4. `xcrun xctrace list devices` — verify iPhone appears

### 5b: Code Signing
1. `cp project.local.yml.template project.local.yml`
2. Ask dev for their Apple Development Team ID (Xcode → Settings → Accounts)
3. Edit `project.local.yml`: set `DEVELOPMENT_TEAM` to their Team ID
4. `make generate` — regenerate with signing config
5. If custom bundle IDs needed: update `project.yml` bundle identifiers and App Group in both `entitlements.properties` and `PersistenceConfig.swift`

### 5c: Build and Run
1. Open Slate.xcodeproj
2. **Select iPhone as destination before building** (important — see [troubleshooting.md](references/troubleshooting.md))
3. Cmd+R
4. If "Untrusted Developer" → Settings → General → VPN & Device Management → Trust

### 5d: Verify Widgets
1. Home screen → long-press → + → search "Slate" → add medium widget
2. Lock screen → long-press → Customize → add rectangular widget
3. Test notifications: swipe right on todo → bell → "In 10 seconds" → lock phone → long-press notification → "Mark Done"

## Phase 6: Final Checklist

Present and mark each:

```
[ ] Xcode 26.2+ installed and licensed
[ ] Nix installed, direnv hooked into shell
[ ] Dev shell activates (xcodegen, swiftlint, xcbeautify on PATH)
[ ] iOS 17+ simulator available
[ ] project.local.yml created and configured (required)
[ ] make generate succeeds with entitlements validated
[ ] make build succeeds
[ ] App runs in simulator (Cmd+R)
[ ] (Optional) App runs on iPhone
[ ] (Optional) Home screen widget works
[ ] (Optional) Lock screen widget works
[ ] (Optional) Notification actions work
```

On all checks passed: "You're all set. Run `make generate` after adding/removing source files. See README.md for reference. Ready to open pull requests."

## Tips

Present these after setup is complete:

### Git hooks are automatic

The dev shell installs git hooks via symlinks to the Nix store. They're activated the moment you enter the shell — no manual setup needed.

- **pre-commit**: If `project.yml` is staged, regenerates the xcodeproj and validates entitlements. Also runs SwiftLint on staged `.swift` files (blocks commit on errors — use `--no-verify` to skip in emergencies).
- **post-merge**: After `git pull`, if `project.yml` changed, auto-runs `make generate`. If `flake.nix`/`flake.lock` changed, reminds you to `direnv reload`.

### Fix "untrusted substituter" Nix warnings

If you see warnings like `ignoring untrusted substituter` or `ignoring the client-specified setting 'trusted-public-keys'` when entering the dev shell, your Nix user isn't trusted. Give this prompt to a new Claude Code session to fix it:

> My Nix setup shows "ignoring untrusted substituter" and "ignoring the client-specified setting 'trusted-public-keys'" warnings when I use `direnv allow` or `nix develop` in a project. I'm using the Determinate Nix installer on macOS. Configure my system so my user is trusted and the nixos.org cache works without warnings. Check my existing nix.conf first.
