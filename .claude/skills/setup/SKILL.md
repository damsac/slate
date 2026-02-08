---
name: setup
description: Interactive developer environment setup for the Slate iOS project. Use when a new developer needs to onboard, when setting up a new machine, or when someone runs /setup. Walks through system checks, project generation, simulator build, physical device deployment, and widget verification step-by-step.
---

# Slate Developer Setup

Interactive walkthrough to get a new developer from zero to a working Slate build on simulator and real iPhone.

## Rules

- **Ask before reading files outside `~/Slate/`** — explain why.
- **Ask before installing system packages** — present what and why, let the dev approve.
- **Never run destructive commands** without explicit approval.
- **One phase at a time** — confirm each passes before moving on.
- **Report results as checklists** after each phase.

## Phase 1: System Requirements

Check each, report pass/fail:

1. `sw_vers` — macOS 14+
2. `xcode-select -p` and `xcodebuild -version` — Xcode 15+
3. Xcode license — `sudo xcodebuild -license status` (ask before sudo). If not accepted: `sudo xcodebuild -license accept`
4. Homebrew — check `/opt/homebrew/bin/brew` or `/usr/local/bin/brew`. Needed for XcodeGen.
5. XcodeGen — `which xcodegen`. If missing: `brew install xcodegen`
6. `git --version`

Fix gaps with dev approval before continuing.

## Phase 2: Simulators

1. `xcrun simctl list runtimes` — need iOS 17+
2. `xcrun simctl list devices available` — need an iPhone simulator
3. No runtime → tell dev: Xcode → Settings → Platforms → download iOS 17+
4. No device → `xcrun simctl create "iPhone 16" com.apple.CoreSimulator.SimDeviceType.iPhone-16 <runtime-id>`

## Phase 3: Generate Project

1. Run `xcodegen generate` from `~/Slate`
2. Check both entitlements files contain `group.com.slate.shared`. XcodeGen often wipes these — restore if needed. See [troubleshooting.md](references/troubleshooting.md) for details.
3. `xcodebuild -project Slate.xcodeproj -list` — confirm targets: `Slate`, `TodoWidgetExtension`

## Phase 4: Simulator Build

1. Pick an available simulator from Phase 2
2. `xcodebuild -scheme Slate -destination 'platform=iOS Simulator,name=<device>,OS=latest' -configuration Debug build`
3. On failure, check [troubleshooting.md](references/troubleshooting.md) for common fixes
4. On success: "Simulator build works. Open Slate.xcodeproj, select the simulator, Cmd+R to run."

## Phase 5: Physical Device (Optional)

Ask the dev if they want to set this up. Skip if no.

### 5a: Device Prep
1. iPhone must be iOS 17+ (Settings → General → About)
2. Developer Mode on: Settings → Privacy & Security → Developer Mode → toggle (requires restart)
3. Connect USB, unlock, tap "Trust This Computer"
4. `xcrun xctrace list devices` — verify iPhone appears

### 5b: Code Signing
1. Ask dev for bundle ID prefix (e.g. `com.theirname`)
2. Update `project.yml`: both `PRODUCT_BUNDLE_IDENTIFIER` values
3. Update App Group in both `.entitlements` and `PersistenceConfig.swift`
4. `xcodegen generate` — restore entitlements after

### 5c: Build and Run
1. Open Slate.xcodeproj
2. Both targets → Signing & Capabilities → set Apple ID team
3. **Select iPhone as destination before setting team** (important — see [troubleshooting.md](references/troubleshooting.md))
4. Cmd+R
5. If "Untrusted Developer" → Settings → General → VPN & Device Management → Trust

### 5d: Verify Widgets
1. Home screen → long-press → + → search "Slate" → add medium widget
2. Lock screen → long-press → Customize → add rectangular widget
3. Test notifications: swipe right on todo → bell → "In 10 seconds" → lock phone → long-press notification → "Mark Done"

## Phase 6: Final Checklist

Present and mark each:

```
[ ] Xcode 15+ installed and licensed
[ ] XcodeGen installed
[ ] iOS 17+ simulator available
[ ] Project generates cleanly
[ ] Simulator build succeeds
[ ] App runs in simulator
[ ] (Optional) App runs on iPhone
[ ] (Optional) Home screen widget works
[ ] (Optional) Lock screen widget works
[ ] (Optional) Notification actions work
```

On all checks passed: "You're all set. Run `xcodegen generate` after adding/removing source files. See README.md for reference. Ready to open pull requests."
