---
id: "005"
title: "Meta-Workflow Infrastructure"
status: active
author: gudnuf
project: Slate
tags: [meta-workflow, documentation, session-miner, context-limits, haiku-model]
previous: "004"
sessions:
  - id: 86e4208f
    slug: session-miner-and-meta-tooling
    dir: Slate
  - id: d3c3dd71
    slug: meta-workflow-context-limit-diagnosis
    dir: Slate
  - id: ad31e146
    slug: meta-workflow-execution-entries-003-005
    dir: Slate
prompts: []
created: "2026-02-09T00:27:22Z"
updated: "2026-02-09T01:23:55Z"
---

# 005: Meta-Workflow Infrastructure

## Context

Entries 003-004 were written by the meta-workflow system itself, but the tooling that made that possible was built and debugged across these sessions. This entry covers the creation of the session-miner agent, the diagnosis of context limit failures when processing 42 sessions (30MB of JSONL), and the refactored architecture that made batch documentation viable.

## Timeline

### Session-Miner Agent Creation (`86e4208f`)

Created `.claude/agents/session-miner.md` — a lightweight Haiku-model agent with only Read + Grep tools. Reads a single JSONL transcript and returns a structured summary: GOAL, OUTCOME, DECISIONS, PROBLEMS, FILES, COMMITS, THINKING.

Uses chunked reading: first 100 lines, middle 100, last 100. This handles both 15KB and 3.7MB files without hitting context limits.

Updated the meta-workflow SKILL.md to formalize the orchestration pattern: Python-based session discovery, batch size of 8, parallel mining with result aggregation.

**Design principle**: Miners handle transcript parsing (cheap, parallel). The meta-workflow orchestrates discovery, git log fetching, dispatch, and synthesis (expensive, serial). Keeps the main agent context-light.

### Context Limit Diagnosis (`d3c3dd71`, ~1.5 hrs)

Investigated why `/meta-workflow` failed on the full session backlog.

**Root cause**: The skill launched unlimited parallel subagents on all 42 session files (30MB total). Even with "keep under 600 words" instructions, the main agent still had to: discover all sessions (bloats context), launch 20+ subagents, collect all results back, then write the narrative.

**Fixes designed**:

| Problem | Fix |
|---------|-----|
| 42 sessions at once | Date-based filtering — only mine since last entry |
| No batch limit | Cap at 8 sessions per entry |
| Large files read whole | Chunked reading (first+middle+last 100 lines) |
| Results bloat main context | Run miners in background, pull only summaries |
| Sonnet model for extraction | Haiku model — 40-50% fewer tokens, sufficient quality |

### Execution — Entries 003-005 (`ad31e146`, ~1.5 hrs)

Applied the refactored workflow to mine 23 sessions and create three narrative entries.

Launched 24 Haiku miners concurrently. Grouped results by functional scope (docs/onboarding, CI implementation, CI refinement) rather than chronological time. Synthesized miner outputs into timeline phases with decisions, patterns, and cross-references.

**Problem**: First 4 miners failed due to wildcard paths not resolving. Fixed by providing exact file paths on retry. Demonstrates that miners need explicit paths, not glob patterns.

**Outcome**: Three entries (~250-280 lines each) covering the full CI/CD implementation arc.

## Architecture

The meta-workflow operates as a three-phase system:

```
Phase 1: Discovery
├─ Read existing entries' sessions: frontmatter → build covered set
├─ Python script finds uncovered sessions by date + size
└─ Group into batches of 8

Phase 2: Mining
├─ Fetch git log for time range (one command, pass slices to miners)
├─ Launch parallel Haiku miners (run_in_background: true)
└─ Each miner reads chunked JSONL, returns structured summary

Phase 3: Synthesis
├─ Collect miner results
├─ Organize by functional scope into timeline phases
└─ Write narrative with decisions, problems, patterns
```

## Learnings

1. **Haiku is sufficient** for transcript summarization — don't default to Sonnet
2. **8 sessions per entry** is practical — parallel mining showed good throughput without context bloat
3. **Chunked reading should be default** — first+middle+last 100 lines works for files of any size
4. **Explicit paths beat wildcards** — session miners need exact file paths
5. **Always use Python for session discovery** — the Nix devShell provides GNU coreutils, so macOS `stat`/`date` flags silently produce wrong output
6. **Background agents reduce context pressure** — main agent continues planning while miners work

## What's Next

The meta-workflow infrastructure is production-ready. Entries 003-004 prove it works at scale. Remaining:
1. Formalize as a quarterly/weekly documentation cycle — date-filter to sessions since last entry, mine, publish
2. Consider dynamic batch sizes based on file size rather than fixed 8
3. Optional validation — miners could check that returned commits exist in git log
