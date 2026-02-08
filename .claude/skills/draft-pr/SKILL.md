---
name: draft-pr
description: >
  Create a pull request with an information-dense description that walks reviewers through
  what was done and why. Use when the user says "draft pr", "create pr", "open pr", or
  is ready to submit work for review. Analyzes changes, workflows used, and documentation
  to produce a PR that teaches reviewers about the work.
---

# Draft PR

Create a pull request that walks reviewers through the developer's process — not just what changed, but how and why.

## Critical Rules

- **Understand before writing.** Review all changes from `<target_branch>..HEAD`, read related prompt files in `workflows/prompts/`, and read modified files before drafting anything.
- **Link to branch files, not relative paths.** PR descriptions render on GitHub — use `https://github.com/<owner>/<repo>/blob/<branch>/path` for all file links.
- **Point to documentation, don't repeat it.** If a meta entry explains a decision, link to it. Don't paste the explanation into the PR.
- **Dense > verbose.** The team iterates quickly. Every sentence should earn its place.

## Step 1: Confirm target branch and sync

Before anything else, determine the correct base branch for this PR.

1. Check the current branch: `git branch --show-current`
2. Check if there's a parent feature branch between this branch and `master`:
   ```bash
   git log --oneline --graph --all | head -30
   ```
3. If the branch was created from another feature branch (not `master`), confirm the target with the human via `AskUserQuestion` — e.g., "This branch was created from `feat/initial-setup`. PR against that, or against `master`?"
4. If the branch is directly off `master`, use `master` as the base without asking.
5. Rebase on the latest target branch:
   ```bash
   git fetch origin
   git rebase origin/<target_branch>
   ```

## Step 2: Understand the changes

Read in parallel:

1. **Diff against target**: `git log <target_branch>..HEAD --oneline` and `git diff <target_branch>..HEAD --stat` — scope the review to exactly what this PR introduces
2. **Prompt files**: Check `workflows/prompts/` for any prompt files created or modified in this branch (`git diff <target_branch>..HEAD --name-only | grep workflows/`). Read them — they contain the human's intent and Claude's execution notes.
3. **Meta entries**: Check if any meta entries were added or updated in this branch
4. **CLAUDE.md**: Check if any learnings were added or rules changed
5. **Changed files**: Read the key files that were modified — focus on infrastructure and shared code, not boilerplate

Build a mental model: what was the developer trying to do, what decisions did they make, and what should a reviewer understand?

## Step 3: Determine PR structure

Infer the PR type from the changes:

- **Files in `.claude/skills/`, `workflows/`, `CLAUDE.md`, `Makefile`, `.gitignore`** → tooling/DX change
- **Files in `Slate/Views/`, `Slate/Theme/`** → UI change
- **Files in `Slate/Models/`, `Slate/Shared/`, `SlateWidget/`** → feature or infrastructure
- **Mix of app code + new skill/workflow files** → feature with DX investment
- **Small diff, single concern** → fix or refactor

If the type is genuinely ambiguous (e.g., a large PR touching many concerns), ask the human. Otherwise, proceed — minimize human-in-the-loop when the diff speaks for itself.

The structure adapts based on type:

**Initial setup / onboarding-heavy**: Walk reviewers through the repo as a learning experience. Lead with workflow and philosophy, code second. Use numbered steps.

**Feature / fix**: Lead with what changed and why. Link to the meta entry for the full story. Focus the PR on what reviewers need to verify.

**Tooling / skills**: Explain what the skill does, when to use it, and how it changes the workflow. Include a "try it" section.

## Step 4: Draft the PR description

### Structure template

```markdown
## <Opening context>
1-3 sentences: what this PR is and why it matters. Not a commit message — frame it for the reviewer.

---

## Step-by-step guide (for complex PRs)
Walk the reviewer through the work in the order they should understand it.
Each step: what to read/do, and WHY you're asking them to do it.
Point to files with full branch URLs.

## Key decisions (if applicable)
Table: Decision | Choice | Where to read more
Link "where to read more" to specific sections of meta entries or files.

## Architecture (if changed)
ASCII diagram of how components connect. Keep it simple.

## Checklist
- [ ] Items matching the steps above
- [ ] Testing steps
```

### Link format

All file links must use the full branch URL:
```
https://github.com/<owner>/<repo>/blob/<branch>/<path>
```

Determine owner/repo from `git remote get-url origin`. Determine branch from `git branch --show-current`.

### Diagrams

Use ASCII art in fenced code blocks (renders on GitHub). Use these when showing:
- Component relationships (app ↔ widget ↔ shared data)
- Data flow
- Workflow sequences

## Step 5: Handle commits

Check if there are uncommitted changes that should be part of this PR.

- If work is uncommitted: stage and commit with a concise message. Follow `CLAUDE.md` commit rules — update any prompt files with `commit_hash` and `status`.
- If already committed: verify the commit message is clear.
- If multiple commits: the PR description should cover the full scope, not just the latest commit.

## Step 6: Push and create PR

```bash
# Get repo info
REMOTE=$(git remote get-url origin)
BRANCH=$(git branch --show-current)
BASE=<target_branch>  # determined in Step 1

# Push
git push -u origin $BRANCH

# Create PR — prefer opening in browser so the human can review before submitting
gh pr create --base $BASE --head $BRANCH --title "<title>" --body "<body>" --web
```

**Prefer `--web`** so the human sees the PR in their browser and can edit before clicking "Create". If `--web` isn't supported or the user wants it created directly, use `--draft` to create as a draft PR.

After creation, open the PR URL in the browser:
```bash
open <pr-url>
```

## Step 7: Annotate key changes

After the PR is created, post inline review comments on files that are important for humans to understand deeply. Focus on:

- **Skills and CLAUDE.md** — these are instructions Claude follows. Explain what each section does, why it's written that way, and where Claude might misinterpret or drift. Be verbose here — reviewers need to understand these files well enough to spot when Claude is going in the wrong direction.
- **Infrastructure/shared code** — files like `PersistenceConfig.swift` or `project.yml` that multiple targets depend on. Explain the design decisions and tradeoffs.
- **Workflow files** — if new meta entries or prompt files were created, annotate the pattern so reviewers understand the documentation system.

For each comment:
- Explain the **design decision** behind the code, not just what it does
- Flag **potential drift** — where could Claude misinterpret this instruction?
- Note **connections** to other files or skills that the reviewer should understand together

Use `gh api repos/<owner>/<repo>/pulls/<number>/reviews --method POST --input <json-file>` to post a review with inline comments.

## Step 8: Save prompt file

Create `workflows/prompts/<unix-timestamp>.md` documenting this PR creation, per the prompt skill format. Link it to the commit.

## Style Guide

- **PR titles**: `<type>: <what>` — e.g., `feat: interactive widget checkboxes`, `fix: App Group fallback on unsigned builds`, `dx: add /prompt skill`
- **No emoji** unless the user uses them
- **Tables** for structured comparisons (decisions, file lists)
- **Code blocks** for commands, file trees, architecture diagrams
- **Bold** key terms for scan-reading
- **Arrows** (→, ←, ↔) for flow descriptions
