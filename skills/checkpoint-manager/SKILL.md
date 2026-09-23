---
name: checkpoint-manager
description: Decides which phase(s)/group(s)/section(s) of the technext-sales-proposal pipeline actually need to run, and reads/writes the client's checkpoint file so a run can resume from where it left off instead of always rebuilding from scratch. Called by the technext-sales-proposal orchestrator skill at the start of every invocation, and again after each phase completes.
---

# Checkpoint manager — run one phase at a time instead of the whole pipeline

Running the full Phase 1→4 pipeline in one go is the default, but it's also the
slowest/most expensive path — if the user only wants to re-run Group B after a bad
first pass, or just wants Phase 4's validator re-checked after a manual edit, they
shouldn't be forced through everything again.

## What to do when called

1. **Read `<client-slug>-checkpoint.json`** if it exists — a small file tracking
   what's done:
   ```json
   { "phase1_groupA": "done", "phase1_groupB": "done", "phase1_groupC": "pending", "phase1_groupD": "pending", "phase2": "pending", "phase3": "pending", "phase4": "pending" }
   ```
   If it doesn't exist yet, this is a fresh run — everything is `"pending"`.
2. **Ask the orchestrator's caller (via the orchestrator), right after the client is
   confirmed**: *"Chạy toàn bộ pipeline luôn, hay chỉ chạy 1 phase cụ thể?"* Report
   back which phases/groups are already `"done"` vs. `"pending"` so the orchestrator
   can decide (or ask the user) what to actually dispatch this run.
3. **After each phase/group completes**, update the checkpoint file and report what
   just ran — e.g. *"Đã chạy xong Phase 1 Group A + B (2 agent). Group C, D, Phase
   2-4 vẫn đang pending."* This tracks **how many `Agent` calls were made**, a rough
   proxy for cost — not an exact token/dollar count.

## Rules for what counts as a valid checkpoint file

- **Every intermediate file must be a real, directly-openable HTML page — never a
  bare `<section>` fragment saved on its own.** A fragment can't be previewed in a
  browser, which is exactly when you most want to look at it. So
  `<client-slug>-p1-groupA.html` (and B/C/D) must be a **full copy of
  `~/.claude/skills/technext-sales-proposal/assets/proposal-template.html`** with
  that group's real sections filled in and every other section left as its original
  `placeholder-note` — openable and previewable on its own, exactly like the final
  deliverable, just with most sections still empty.
- A shared `<client-slug>-p1-digests.json` holds each group's 3–5-point digest (kept
  separate since the `front-matter-writer` skill only needs the digests, not full
  HTML).
- **Phase 2** (`front-matter-writer` skill) saves its own preview the same way — a
  full template copy with just the front-matter sections filled in — to
  `<client-slug>-p2-frontmatter.html`.
- **Phase 3 (`assembler` skill)** requires all of Phase 1 (4 groups) + Phase 2 to be
  `"done"` — if any are still `"pending"`, say so and stop rather than assembling
  with gaps.
- **Phase 4 (`mechanical-validator` + `judgment-reviewer` skills)** only needs Phase
  3's `<client-slug>-proposal.html` to exist — it can be re-run alone any time (e.g.
  right after a manual fix) without touching Phases 1–3.

## Section-level touch-ups — smaller than a whole group

A group is 6–14 sidebar sections bundled into one `Agent` call — if the user only
wants one specific section redone (e.g. "chỉ nghiên cứu lại phần Digital & Web
Presence thôi" — that's one section inside Group A, not all of Group A), don't
re-run the whole group:
1. Identify which subagent owns that section (match the section name against
   `~/.claude/skills/technext-sales-proposal/assets/menu-structure.md`, or check
   which of the 4 `.claude/agents/*.md` subagent definitions lists it).
2. Have the orchestrator spawn a single, narrowly-scoped `Agent` call for **just that
   one section** (still give it the real template contents + `research-rules.md` —
   a smaller scope doesn't mean a lower quality bar).
3. Open the group's existing `<client-slug>-p1-group<X>.html`, find that section's
   `<section id="...">...</section>` block, and replace only that block in place —
   every other section stays untouched, byte for byte.
4. The group's checkpoint status stays whatever it already was (this is an in-place
   patch, not a new phase) — no new checkpoint field needed.

If the user doesn't know which group owns a section, they don't need to — just name
the section (as it appears in the sidebar) and resolve the mapping yourself.
