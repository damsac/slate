# Slate

## Commit Rules

When committing code changes, check `workflows/prompts/` for any prompt files related to the current work:
- Update the `commit_hash` field in frontmatter with the commit SHA
- Update `status` from `executed` to `committed`
- Fill out the `Result` section (outcome, approach taken, deviations, or `discarded`)
- Stage the prompt file updates alongside the code changes in the same commit

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
