---
name: source-auditor
description: A hard gate, not an FYI report — re-checks all 4 research subagents' findings.json together, collapses sources that trace to one origin, and re-grades confidence. Blocks front-matter-writer/html-renderer from proceeding until every finding is either properly sourced, tagged .assess, or sent back to its owning subagent for a fix. Called by the technext-sales-proposal orchestrator right after all 4 Phase 1 subagents finish, before any writing/rendering step touches their output.
---

# Source auditor — a gate, not a report

**This is the direct answer to "what if the data is wrong — surely someone reviews it
before it gets used?"** Before this skill existed, each subagent graded its own
sources while writing, then the content just flowed straight into the final page —
nobody who wasn't the original writer ever double-checked it. This skill is that
second, independent set of eyes, and it has the power to **stop bad data from
reaching the written proposal**, not just note it in a log.

## What to do

Read all 4 `<client-slug>-findings.json` files (from `research-due-diligence-agent`,
`research-ops-tech-agent`, `research-delivery-growth-agent`, `tools-documents-agent`).
For every entry:

1. **Source independence check.** If the same claim (or a claim it depends on) is
   backed by multiple URLs that all trace back to one original press release/bio/
   listing (a content-farm re-post, a directory scrape of the same source), collapse
   them to one real source — don't let duplicate mirrors count as independent
   corroboration.
2. **Re-grade confidence**, independently of what the writing agent originally
   claimed:
   - `Confirmed` entries: verify the cited meeting/transcript reference actually
     exists in this run's Phase 0 notes — a `Confirmed` grade with no real meeting
     behind it gets downgraded to `D`/`.assess`.
   - `A`/`B`/`C` entries: spot-check that the `source_url` is a real, resolvable URL
     and its domain plausibly matches the claim's subject (a claim about the client's
     revenue citing an unrelated news site is a red flag, not a pass).
   - Any entry with a missing/empty `source_url` and no `Confirmed`/`.assess`
     equivalent is an **automatic fail** for that claim.
3. **Count real independent sources** after dedup (step 1) — this is the number that
   matters for "is this proposal well-sourced," not the raw citation count each
   subagent reported.

## The gate — this is the part that makes it a gate, not a report

Write `audited-findings.json` (same shape as the input files, merged, with
`grade` fields corrected and duplicates collapsed) **plus** a `blocking_issues` array.
- **If `blocking_issues` is non-empty**: stop here. Route each issue back to the
  subagent that owns that section (match the `section` field to the Group A/B/C/D
  ownership list) with the specific problem named (not "fix your sources" — say
  exactly which claim, which URL, which reason it failed). **Do not let
  `front-matter-writer`, `chart-data-analyst`, or `html-renderer` proceed on this
  run until the affected subagent re-submits a fix and it passes re-audit.** A
  faster-but-wrong report is not an acceptable trade — this is the one step in the
  pipeline whose whole job is refusing to let ungrounded content through.
- **If `blocking_issues` is empty**: `audited-findings.json` is what
  `chart-data-analyst` and `front-matter-writer` read from here on — never the raw,
  un-audited per-subagent `findings.json` files directly.

## Output

`audited-findings.json` (always) and, only when something failed, a clear per-issue
routing note back to the owning subagent. Downstream skills (`chart-data-analyst`,
`front-matter-writer`, `html-renderer`) must not run against unaudited data.
