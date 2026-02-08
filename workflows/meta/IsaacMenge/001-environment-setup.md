---
id: "001"
title: "Environment Setup & First Build"
status: active
author: IsaacMenge
project: Slate
tags: [setup, xcode, nix, direnv, simulator, device-deployment]
previous: "000"
sessions:
  - id: 45ea715b
    slug: first-setup-attempt
    dir: slate
  - id: f5c1b40f
    slug: full-setup-and-build
    dir: slate
prompts: []
created: "2026-02-08T17:43:00Z"
updated: "2026-02-08T18:30:00Z"
---

# 001: Environment Setup & First Build

## Context

First attempt at cloning the Slate repo and getting the app running. The project uses Nix + direnv for reproducible tooling and XcodeGen for project generation. Encountered several compatibility issues due to running Xcode 26.2 (newer than the original developer's environment).

## Timeline

### Phase 0: First Setup Attempt (`45ea715b`, ~5 min)

**What**: Ran `/setup` skill from a fresh Claude Code session. The skill was discovered and executed successfully in this session, confirming the skill system works when the session starts from the correct environment.

### Phase 1: Clone & Branch Checkout (`f5c1b40f`, ~2 min)

**What**: Cloned repo, attempted `git checkout feat/initial setup` (with space) — failed. Branch was actually `feat/initial-setup` (hyphen).

**Problem**: Branch name had a hyphen, not a space. Git interpreted the space as two separate pathspecs.

### Phase 2: Environment Activation (~5 min)

**What**: `direnv allow` triggered, but Claude Code session didn't have the Nix tools on PATH.

**Problem**: The Claude Code process was started before direnv activated the dev shell. Tools like `xcodegen`, `swiftlint`, `xcbeautify` weren't available.

**Solution**: Used `eval "$(direnv export bash 2>/dev/null)"` inline before commands to inject the Nix environment into the current session. Avoided the need to restart.

**Lesson**: The `/setup` skill documents this (Phase 2, step 4) — recommends exiting and resuming. The inline eval workaround is faster.

### Phase 3: System Checks (~2 min)

**What**: Verified all prerequisites. Everything passed.

| Check | Result |
|-------|--------|
| macOS 14+ | macOS 26.2 |
| Xcode 15+ | Xcode 26.2 |
| Nix | Determinate Nix 3.15.1 |
| direnv | 2.37.1 |
| git | 2.50.1 |
| iOS simulator | iOS 26.2, multiple devices |

**Problem**: Duplicate "iPhone 17 Pro" simulator (one lowercase `iphone 17 pro`). Deleted the duplicate.

### Phase 4: Build Failures (~20 min)

**What**: `make build` (CLI via xcodebuild) failed with linker error. Multiple fix attempts before switching to Xcode GUI.

**The linker error**:
```
ld: -objc_abi_version '-Xlinker' not supported (expected 2)
```

**Root cause**: Xcode 26's new linker (`ld-1230.1`) misinterprets `-Xlinker` flag pairs when `ld` is invoked directly by the build system. This is an XcodeGen 2.44.1 + Xcode 26 compatibility issue — the `-Xlinker` prefix (a compiler-driver flag) is being passed directly to the linker binary.

**Attempted fixes that didn't work**:
- Updating `SWIFT_VERSION` from `5.9` to `6.0` (fixed the linker error but introduced Swift 6 strict concurrency errors)
- Changing `static var` to `static let` in `ToggleTodoIntent.swift` (fixed concurrency but linker error returned)
- Removing `LD_RUNPATH_SEARCH_PATHS` from widget target
- Setting `LD_RUNPATH_SEARCH_PATHS: "$(inherited)"` only

**What worked**: Building through Xcode GUI (Cmd+R) instead of `xcodebuild` on the command line. The Xcode GUI build system handles the linker invocation correctly.

**Open question**: The `make build` command is broken on Xcode 26. This needs a fix — either update XcodeGen, use the classic linker, or find the correct build settings. This affects CI/CD if any is set up.

### Phase 5: Simulator Launch (~3 min)

**What**: First Xcode GUI build succeeded but the simulator showed a blank white screen. Second launch after rebooting the simulator worked.

**Problem**: Simulator process failed to launch on first try ("No such process" error). Standard simulator glitch.

**Solution**: `xcrun simctl shutdown <id>` + `xcrun simctl boot <id>`, then Cmd+R again.

### Phase 6: Device Deployment (Aborted)

**What**: Attempted to deploy to physical iPhone (iOS 18.6.2). Hit multiple blockers.

**Problems encountered**:
1. iPhone not detected by Mac initially — required unplug/replug and trust dialog
2. Developer Mode not visible on iOS 18 — only appears after Xcode attempts a device build
3. App Group identifier `group.com.damsac.slate.shared` rejected — belongs to original developer's Apple account. Required changing bundle IDs to `com.isaacwm.slate.*` across `project.yml`, `Makefile`, and `PersistenceConfig.swift`
4. **Disk full** (117 MB free on 228 GB drive) — blocked all operations including git. Cleared Xcode DerivedData to recover.

**Decision**: Aborted device deployment. Reverted all bundle ID changes to keep the branch clean for the partner. Will revisit when disk space is available.

## Developer Patterns Observed

- **Xcode version skew is a real problem**: The project was built on an older Xcode. Xcode 26's new linker breaks the CLI build. This should be documented as a known issue.
- **CLI build != GUI build**: `xcodebuild` and Xcode GUI handle the linker differently on Xcode 26. Can't assume one works because the other does.
- **Bundle ID ownership**: Free Apple developer accounts can't use another developer's bundle identifiers or App Groups. Device deployment requires per-developer bundle IDs — the `project.local.yml` pattern handles the team ID but not the bundle IDs themselves.
- **Disk space**: Xcode DerivedData + Nix store + simulator images can quietly consume all available space. Worth adding a disk space check to `/setup`.

## Open Questions

- How to fix `make build` for Xcode 26? Options: update XcodeGen, add `-ld_classic` flag, or accept GUI-only builds.
- Should bundle ID overrides be supported in `project.local.yml` for device deployment?
- Should `/setup` check available disk space before starting?

## What's Next

App runs in simulator. Next: create this journal entry, open a PR, and start contributing features. Device deployment deferred until disk space is sorted.
