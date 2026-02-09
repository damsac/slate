---
name: meta-workflow
description: >
  Create or update developer journey documentation in workflows/meta/.
  Use when the user says "meta", "meta-workflow", "document this session",
  "write up what we did", or wants to create a changelog-style entry
  documenting developer thinking, decisions, and session history.
  Also use after completing a non-trivial PR or feature.
---

# Meta Workflow

Create structured developer journal entries in `workflows/meta/<author>/`.

## Step 1: Resolve Author & Next Entry

```bash
AUTHOR=$(git config user.name)
```

- If `workflows/meta/$AUTHOR/` doesn't exist → create it, start at `000`
- If it exists → `ls workflows/meta/$AUTHOR/*.md`, find highest number, increment

For first-time authors, copy `workflows/meta/000-template.md` as starting point.

## Step 2: Determine Scope

If the user provided explicit scope (e.g., "cover all sessions since last entry", "document the PR review work"), use that. Otherwise, ask (via `AskUserQuestion`) what this entry covers:
- Feature or set of features just completed
- Research / exploration session
- Onboarding (first entry)
- Retrospective on recent work

## Step 3: Mine Conversation History

Session transcripts live in `~/.claude/projects/`. The current project directory is named with the workspace absolute path's separators replaced by dashes (e.g., `/Users/me/Slate` → `-Users-me-Slate`).

### Context budget

Session mining is the most expensive step. **The main agent never reads raw transcripts.** All reading is delegated to `session-miner` agents (`.claude/agents/session-miner.md`) which run on `haiku`, read independently, and return only a compact ~200 word summary each.

### Discovery process

#### 1. Build the covered-sessions set

Read the `sessions:` frontmatter from **every** existing entry in `workflows/meta/<author>/`. Collect each `id:` value into a set of 8-character prefixes. These sessions are already documented and must be excluded.

#### 2. Find uncovered sessions via Python

**Always use Python for session discovery.** Shell-based `stat`/`date` commands are unreliable — the Nix devShell provides GNU coreutils, so macOS-style flags (`stat -f`, `date -j`) silently fail.

Run this Python script (adjust `covered` set from step 1):

```python
import os, glob, json
from datetime import datetime, timezone

session_dir = os.path.expanduser("~/.claude/projects/-Users-claude-Slate")
covered = {"abcd1234", "efgh5678"}  # ← paste actual covered prefixes here

sessions = []
for f in sorted(glob.glob(os.path.join(session_dir, "*.jsonl"))):
    basename = os.path.basename(f).replace(".jsonl", "")
    prefix = basename[:8]
    if prefix in covered:
        continue
    size = os.path.getsize(f)
    if size < 5000:  # skip trivial sessions (<5KB)
        continue
    mod = os.path.getmtime(f)
    ts = datetime.fromtimestamp(mod, tz=timezone.utc).isoformat()
    sessions.append((mod, prefix, size, ts, f))

sessions.sort(key=lambda x: x[0])
for i, (mod, prefix, size, ts, path) in enumerate(sessions, 1):
    print(f"{i:2d}. {prefix} ({size//1024}KB) {ts} {path}")
print(f"\nTotal: {len(sessions)} uncovered substantive sessions")
```

#### 3. Batch and dispatch

**Group sessions by theme, not rigid count.** Scan session slugs and timestamps to identify natural thematic clusters (e.g., "all CI/CD work", "meta-workflow tooling", "feature X"). Each cluster becomes one entry regardless of whether it has 3 or 13 sessions.

**Practical limits:** Keep each entry under ~15 sessions. If a thematic cluster is larger, split it at a natural boundary (design vs. implementation, or before/after a major decision).

If uncovered sessions span multiple themes:
- Write one entry per theme in this invocation (if context allows)
- Or process the most cohesive cluster first and report a **continuation prompt** for remaining themes:

```
/meta-workflow continue. Entry <NNN> covers <theme> through <last-prefix> (<timestamp>).
Remaining uncovered sessions (<M> total):
 1. <prefix> (<size>KB) <slug> ...
Group by theme and write the next entry.
```

#### Git log pre-fetch

Before dispatching miners, run **one** `git log` command covering the full time range of the batch:

```bash
git log --oneline --all --date-order --after="<earliest-session-timestamp>" --before="<now>"
```

This is the only git command the main agent runs. Split the output by timestamp ranges so each miner receives only the commits from its session's time window.

#### Dispatch miners

For each session in the batch, launch a `session-miner` agent:
- `subagent_type: "session-miner"`
- `run_in_background: true`
- `prompt:` formatted as:

```
/path/to/session.jsonl
workdir: /Users/claude/Slate
commits:
<git log lines from this session's time window>
```

Each miner correlates the commits with transcript content and reports which commits belong to that session in its COMMITS output field.

Launch **all** miners in a single message so they run concurrently.

#### 4. Collect results

After all background agents finish, read each agent's output. Each returns a structured summary (~200 words) including relevant git commits. Combine them chronologically.

**The main agent does NOT read raw transcripts or analyze git history.** The single `git log` pre-fetch is a mechanical step — all interpretation and correlation is delegated to miners.

#### 5. Proceed to Step 4 using only the collected summaries as source material.

## Step 4: Write the Entry

File: `workflows/meta/<author>/<NNN>-<slug>.md`

### Frontmatter

```yaml
---
id: "<NNN>"
title: "<descriptive title>"
status: active | completed
author: <AUTHOR>
project: Slate
tags: [<relevant>]
previous: "<NNN-1>"  # omit for 000
sessions:
  - id: <session-uuid-prefix>
    slug: <short-description>
    dir: <project-dir-name>
prompts: []  # backlinks filled as prompts are created
created: "<ISO 8601>"
updated: "<ISO 8601>"
---
```

### Body structure

```markdown
# <NNN>: <Title>

## Context
<1-3 sentences: what was happening, why this work started>

## Timeline
### <Descriptive name> (`<session-id>` or `<id1>`, `<id2>` if multiple sessions)
<What was done, decisions made, problems hit — in flowing prose, not rigid sub-headers>

## Architecture Snapshot  (only if architecture changed)

## Patterns
- Unique, non-obvious insights only — not restated observations
- Focus on "what worked" and "what to avoid"

## Open Questions

## What's Next
```

### Writing guidelines for the body

- **Merge related sessions into one phase.** If 3 sessions all work on testing, that's one "Test Strategy & Implementation" phase with multiple session IDs, not 3 separate phases.
- **Drop trivial sessions entirely.** If a session has no decisions, no problems, and no meaningful outcome (e.g., "opened Xcode"), omit it from the entry. Don't include it with a disclaimer about being trivial.
- **Weave cross-references into flow.** Write "The Makefile validation still checked the literal string from the earlier refactor" — not a bolted-on "Connection to Phase 1:" note after each section.
- **No appendices with raw miner output.** The miner summaries are source material, not part of the entry. Synthesize them into the timeline; don't reproduce them.
- **Patterns must earn their place.** Each bullet should be a genuinely reusable insight. "Design then implement" is good. "We merged PRs" is not a pattern.
- **Open Questions should be actionable.** Frame as decisions to make, not vague wonderings. Deduplicate across entries — if a question appeared in a previous entry and is still open, reference it rather than restating.

## Step 5: Cross-Author Context

If other authors have journal entries covering the same time period, read them and add a **"Response to \<Author\>'s Journal Entries"** section after the Timeline. This captures cross-pollination: responding to observations, confirming shared findings, noting disagreements.

Only include this section when there's something substantive to respond to — don't force it.

## Step 6: Handle Assets

Store images, screenshots, mockups in `workflows/meta/<author>/assets/<NNN>/`.

```
workflows/meta/<author>/
  assets/
    000/
      index.html        # UI mockups
      screenshot.png
    001/
      before.png
      after.png
```

Link with relative paths: `[view mocks](assets/000/index.html)`, `![screenshot](assets/001/screenshot.png)`

When user provides screenshots or references external files:
1. Create `assets/<NNN>/` for the entry
2. Copy files there
3. Link with relative paths so clicking opens in browser/viewer

## Style Rules

- **Concise and skimmable** — humans skim, not read linearly. Aim for ~150 lines per entry, not 300.
- **Show thinking, not just output** — "wanted X, considered Y, chose Z because..."
- **Problems are valuable** — document what went wrong
- **No implementation code** — reference files and prompts instead
- **Bold key terms** for scan-reading
- **Session IDs for traceability** — include them in phase headings so readers can find the raw transcript
- **Prefer flowing prose over rigid templates** — "Key decision: ..." mid-paragraph is better than a "**Decisions**:" sub-header for every phase

## Connecting to Prompts

Meta ↔ prompt files (`workflows/prompts/`) are bidirectionally linked:
- Meta `prompts:` frontmatter lists related prompt files
- Prompt `meta:` frontmatter references parent meta entry
- Meta = narrative; prompts = implementation receipts

## Directory Layout

```
workflows/
  meta/
    000-template.md        # new authors copy this
    gudnuf/
      000-research-and-ideation.md
      001-initial-build.md
      assets/000/index.html
    <other-dev>/
      000-onboarding.md
  prompts/
    <timestamp>.md         # linked from meta entries
```
