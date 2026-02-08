# TODO

- [x] **Configure development team for code signing** — Moved to per-developer `project.local.yml` (copy from `project.local.yml.template`). Each dev sets their own `DEVELOPMENT_TEAM` without touching committed files.

- [x] **Move `DEVELOPMENT_TEAM` into per-developer config** — Done via XcodeGen `include:` directive. `project.yml` includes `project.local.yml` (optional, gitignored) which deep-merges developer-specific settings like `DEVELOPMENT_TEAM`.

- [ ] **Understand why `xcodegen generate` wipes Xcode-made changes** — When you make changes directly in Xcode (e.g. adding files, changing build settings, configuring capabilities), running `xcodegen generate` regenerates `Slate.xcodeproj` from scratch based solely on `project.yml`. Any manual Xcode changes that aren't reflected in `project.yml` are lost. Need to learn: which changes should go in `project.yml` vs Xcode, how to avoid losing work, and whether to treat `project.yml` as the single source of truth (recommended) or find a hybrid workflow.

- [ ] **Create `/review-changes` skill** — Should run before `/draft-pr`. Reviews all staged/unstaged changes for bugs, code quality issues, missing error handling, and consistency with existing patterns. Makes code fixes directly. The idea: `/review-changes` cleans up the code, then `/draft-pr` communicates it. Currently `/draft-pr` assumes the code is ready and focuses only on PR description and communication.
