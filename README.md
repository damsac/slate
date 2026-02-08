# Slate

A SwiftUI todo app with interactive widgets and lock screen support. iOS 17+.

## How We Work

Slate is built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) as a core part of the development loop. Instead of memorizing setup steps or project conventions, you talk to Claude and it handles the mechanics.

### Commands

| Command | What it does |
|---------|-------------|
| `/setup` | Interactive walkthrough: checks your system, installs tools, generates the project, builds, and optionally deploys to a physical device |
| `/prompt` | Prompt engineering workflow — structures your idea, reviews it with you, enters plan mode for execution, saves to `workflows/prompts/` |
| `/draft-pr` | Creates an information-dense PR with inline review comments. Opens in browser for final review before submitting. |
| `/meta-workflow` | Creates a developer journal entry in `workflows/meta/` capturing decisions, problems, and thinking. Run after completing a PR or feature. |
| `open xcode` | Opens `Slate.xcodeproj` |

### Typical flow

1. **Have an idea** — describe what you want to build or change
2. **`/prompt`** — Claude cleans up your thinking, you review, say "Do it"
3. **Claude plans & executes** — enters plan mode, you approve the approach, then code changes happen
4. **Commit** — prompt files in `workflows/prompts/` auto-update with commit hash and results
5. **`/draft-pr`** — generates a PR description from your changes and prompt files
6. **`/meta-workflow`** — document the session for future reference

### Commit rules

When you commit code that was driven by a `/prompt`, Claude updates the related prompt file in the same commit:
- Sets `commit_hash` in frontmatter to the new SHA
- Changes `status` from `executed` → `committed`
- Fills in the `Result` section (outcome, approach, deviations)

This keeps the prompt library connected to the git history. You don't need to do this manually — Claude handles it when you ask it to commit.

### Project knowledge

Claude has context about this project via:
- **`CLAUDE.md`** — commit rules, dev environment, learnings (always loaded)
- **`.claude/skills/`** — reusable workflows triggered by slash commands
- **`workflows/meta/`** — developer journals with decision history
- **`workflows/prompts/`** — searchable library of every prompted change

Skills are markdown files written for humans but consumed by Claude at runtime. You can read them directly to understand how any workflow works or crate new ones.
### Developer journals

Each contributor maintains a numbered sequence of journal entries in `workflows/meta/<github-username>/`:

```
workflows/meta/
  000-template.md       ← copy this to get started
  gudnuf/
    000-research-and-ideation.md
    001-initial-build.md
    002-dx-and-polish.md
```

Journals capture the *why* — decision rationale, problems solved, architecture changes. Prompt files capture the *what*. Every non-trivial PR should get a meta entry (run `/meta-workflow` and Claude mines the session transcript for you).

New to the project? Start by reading [`gudnuf/000-research-and-ideation.md`](workflows/meta/gudnuf/000-research-and-ideation.md) for tech stack decisions and app vision.

## Getting Started

### Prerequisites

Install these before running `/setup`:

1. **Xcode 15+** — [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835)
2. **Nix** — `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh`
3. **direnv** — `nix profile install nixpkgs#direnv`, then add the [shell hook](https://direnv.net/docs/hook.html)

### Why Nix + direnv

Every developer gets the exact same tool versions (xcodegen, swiftlint, xcbeautify) pinned in `flake.nix`. No "works on my machine" — `direnv allow` auto-activates the right environment when you `cd` into the project.

### Setup

```bash
git clone <repo> && cd Slate
direnv allow          # Activates Nix devShell — installs xcodegen, swiftlint, xcbeautify
```

Then open Claude Code and run `/setup`. It walks you through everything else — simulator checks, project generation, building, device deployment, widget verification.

### Git hooks (installed automatically)

The Nix devShell installs git hooks on first activation:

- **pre-commit**: Runs SwiftLint `--strict` on staged `.swift` files (blocks commit on errors). If `project.yml` is staged, regenerates the xcodeproj and validates entitlements.
- **post-merge**: If `project.yml` changed after a pull, runs `make generate` automatically. If `flake.nix` or `flake.lock` changed, reminds you to `direnv reload`.

You generally don't need to think about these — they prevent common mistakes silently.

### Branch conventions

| Prefix | Use |
|--------|-----|
| `feat/*` | New features |
| `dx/*` | Developer experience / tooling |
| `fix/*` | Bug fixes |

PRs merge to `master`. Use `/draft-pr` to generate the PR — it reads your prompt files and changes to build a description that teaches reviewers what happened and why.

## Reference

### Project Structure

```
Slate/
├── Slate/                  # Main app target
│   ├── SlateApp.swift
│   ├── Models/TodoItem.swift
│   ├── Views/
│   ├── Shared/             # PersistenceConfig, NotificationManager
│   └── Theme/
├── SlateWidget/            # Widget extension target
│   ├── SlateWidget.swift
│   ├── TodoWidgetView.swift
│   ├── TodoTimelineProvider.swift
│   └── ToggleTodoIntent.swift
├── project.yml             # XcodeGen spec (source of truth)
├── project.local.yml       # Per-developer settings (gitignored)
├── flake.nix               # Nix devShell (pinned tool versions)
├── Makefile                # Standardized build targets
└── workflows/
    ├── meta/               # Developer journals
    └── prompts/            # Prompt library (indexed by frontmatter)
```

### Targets

| Target | Bundle ID | Description |
|--------|-----------|-------------|
| Slate | `com.damsac.slate` | Main app |
| TodoWidgetExtension | `com.damsac.slate.widget` | Interactive widget |

Both targets share `TodoItem.swift`, `PersistenceConfig.swift`, and `Theme.swift` via App Group `group.com.damsac.slate.shared`.

### Make Targets

| Target | Description |
|--------|-------------|
| `make generate` | Run xcodegen + validate entitlements |
| `make build` | Simulator build (no signing required) |
| `make lint` | SwiftLint on both source directories |
| `make clean` | Remove build artifacts |

Run `make generate` after adding/removing source files. It regenerates the `.xcodeproj` and validates that both `.entitlements` files contain the App Group key.

### Widgets

**Home screen**: Run the app once → long-press home screen → **+** → search "Slate" → add the **medium** widget.

**Lock screen**: Long-press lock screen → **Customize** → **Lock Screen** → tap widget slot → search "Slate". The **rectangular** size has interactive check-off buttons (others are display-only). iOS requires unlock before the action executes.

**Not appearing?** Kill and re-run from Xcode. On simulator, `xcrun simctl erase booted` resets fully.

### Notifications

Swipe right on a todo → bell icon → pick a delay. When it arrives, long-press → **"Mark Done"** to check it off without opening the app. Use **"In 10 seconds (test)"** to verify quickly.

### Device Deployment

Handled by `/setup` Phase 5, or manually:

```bash
cp project.local.yml.template project.local.yml
# Set DEVELOPMENT_TEAM to your Team ID (Xcode → Settings → Accounts)
make generate
# In Xcode: select iPhone → Cmd+R
```

First launch: Settings → General → VPN & Device Management → Trust your developer cert.

### Troubleshooting

**"Communication with Apple failed / no devices"**: Plug iPhone in via USB, unlock, "Trust This Computer", then Signing & Capabilities → Try Again.

**"Untrusted Developer"**: On device → Settings → General → VPN & Device Management → Trust.

**Free Apple ID**: Apps expire after 7 days. Paid dev account ($99/yr) removes this.
