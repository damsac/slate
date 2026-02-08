# Slate

A SwiftUI todo app with interactive widgets and lock screen support. iOS 17+.

## How We Work

Slate is built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) as a core part of the development loop. Instead of memorizing setup steps or project conventions, you talk to Claude and it handles the mechanics.

### Commands

| Command | What it does |
|---------|-------------|
| `/setup` | Interactive walkthrough: checks your system, installs tools, generates the project, builds, and optionally deploys to a physical device |
| `/prompt` | Prompt engineering workflow — structures your idea, reviews it with you, executes via subagent, saves to `workflows/prompts/` |
| `/meta-workflow` | Creates a developer journal entry in `workflows/meta/` capturing decisions, problems, and thinking. Run after completing a PR or feature. |
| `open xcode` | Opens `Slate.xcodeproj` |

### Typical flow

1. **Have an idea** — describe what you want to build or change
2. **`/prompt`** — Claude cleans up your thinking, you review, say "Do it"
3. **Claude executes** — code changes happen via subagent, main conversation stays lean
4. **Commit** — prompt files auto-update with commit hash and results
5. **`/meta-workflow`** — document the session for future reference

### Project knowledge

Claude has context about this project via:
- `CLAUDE.md` — commit rules, dev environment, learnings (always loaded)
- `.claude/skills/` — reusable workflows triggered by keywords
- `workflows/meta/` — developer journals with decision history
- `workflows/prompts/` — searchable library of every prompted change

## Getting Started

### Prerequisites

Install these before running `/setup`:

1. **Xcode 15+** — [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835)
2. **Nix** — `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh`
3. **direnv** — `nix profile install nixpkgs#direnv`, then add the [shell hook](https://direnv.net/docs/hook.html)

### Setup

```bash
git clone <repo> && cd Slate
direnv allow          # Activates Nix devShell — installs xcodegen, swiftlint, xcbeautify
```

Then open Claude Code and run `/setup`. It walks you through everything else — simulator checks, project generation, building, device deployment, widget verification.

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
