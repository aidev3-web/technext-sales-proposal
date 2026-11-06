---
name: technext-sales
description: The single entry point for TechNext sales work on the Proposal Portal. Claims an open job from the portal queue (generate_all, ingest_notes, regenerate) through the portal MCP tools and runs the generators — research, proposal, Sales Journey kit, quote module suggestions — against ONE version of the lead record, then saves each output as a draft for an approver to publish. Use when the person says "chạy việc mới", "run the open TechNext sales job for lead <slug>", "có việc gì trên portal", "cập nhật lead từ ghi chú họp", or arrives from the portal's New-lead button deep link.
---

# TechNext Sales — job runner

Implements §5.4/5.5 of `proposal-library/2026-11-05 Design – Một engine cho proposal, journey và báo giá.md`.
Code holds the contracts on the portal (`lib/lead.mjs`, `lib/leads.mjs`, `lib/jobs.mjs`, `lib/journey.mjs`,
`lib/adapters/findings.mjs`, `lib/pricing.mjs`); this skill only orchestrates and does the AI steps.
Never bypass a validator or a refusal to "make it pass".

## Entry
The portal's New-lead button opens Claude Code with exactly:
`Run the open TechNext sales job for lead <slug>: use the technext-sales skill, claim the job, and follow it.`
Without a slug ("chạy việc mới"), list the open jobs and let the person choose.

## Setup (once per person)
The portal MCP server with the person's own personal token (portal → My tokens) carrying scopes
`read`, `facts.write`, `draft.write`, `jobs`. A missing scope shows as `403 token_scope`: tell the person which scope to add; do not retry.

## Hard rules (design §2)
1. The AI never writes a price. Quote = module names with reasons; the portal computes prices (`lib/pricing.mjs`) and refuses any price-like field.
2. One research per lead. If the lead already has a `research` output, read it; do not research again.
3. No customer phone number or email anywhere: facts, prompts, outputs, job labels. Strip them before anything else. The server refuses them too.
4. This skill only saves drafts. It never publishes: an approver/admin publishes on the portal.
5. A follow-up already marked sent is never regenerated or changed.
6. Every generator in one run reads the same record version `V`, saved as `inputs.lead: V`.
7. The first person to claim a lead's job becomes its runner; later jobs of that lead are refused to anyone else (`409 runner_mismatch`). Report who the runner is and stop.

## Flow

1. **Claim.** `list_jobs {status: "open"}` → pick the job for `<slug>` (or let the person choose) → `claim_job {id}`.
   `409 job_taken`: someone else has it, stop. `409 runner_mismatch`: say who the runner is, stop.
2. **Load.** `get_lead {slug}` → keep `record.version` as `V`, `profile`, `stale`, `outputs`.
3. **Run by job kind** (below).
4. **Finish.** `complete_job {id}`; on any failure `fail_job {id, error}` with one line (validator message, missing scope, research blocked). Never save a draft that failed its validator. A claim left open goes back to the queue after 3 h.
5. **Tell the person** in a few lines: which drafts were saved (with versions), any quote that is not computable and its missing facts, and that an approver must publish on the portal.

### generate_all (New button)
1. Research: run the `technext-sales-proposal` research phases (Phase 0 → Phase 1 → source-auditor), seeded from the form facts in `profile`. Result: `audited-findings.json`.
2. Facts: `node tools/findings-to-facts.mjs <audited-findings.json> --usable` → follow `docs/findings-picks-prompt.md` (at most one pick per key, `from` = finding indices) → `node tools/findings-to-facts.mjs <file> picks.json --by <name>` → `add_facts {slug, facts}`. The reply's `version` is the new `V`.
3. `save_output {slug, kind: "research", body: <audited-findings>}` with `inputs: {lead: V}`.
4. With the same `V`, in parallel:
   - **proposal**: the `technext-sales-proposal` writing/assembly/validation phases from the record. Publish the artifact (way A), then `save_output {kind: "proposal", url, inputs: {lead: V, research: <research version>}}`.
   - **journey**: the `sales-journey` `kit.md` recipe with `profile` + `playbook.json` → `{kit, vars}`; check locally with `node lib/journey.mjs` → `save_output {kind: "journey", body: {kit, vars}, inputs: {lead: V, playbook}}`.
   - **quote**: `save_output {kind: "quote", body: {modules: [{module, reason}], missing?: [keys], label}, inputs: {lead: V, matrix}}`. `missing` lists any of `package`, `users`, `addons` absent from `profile`. `label` is `"neil"` only when a `modules` fact with `source.kind: "neil"` exists, else `"ai"`.

### ingest_notes (notes added on a card)
The job carries only `ref: {label, url?}`; read the notes from that link. Never copy raw notes into anything saved.
1. Remove every phone number and email.
2. Extract facts: grade `confirmed`, `source.kind` `call` or `meeting`, `source.ref` = the label/date, only FACT_KEYS; use `supersedes` when replacing an earlier fact of the same key.
3. `add_facts`, then `complete_job`. The portal recomputes `stale`; regenerate jobs follow.

### regenerate (stale outputs only)
Regenerate exactly the kinds listed in `get_lead`'s `stale`, nothing else (staleness comes from `staleOutputs`: an older `inputs.lead` alone is not stale).
- proposal: update, do not rebuild — `technext-meeting-to-proposal` with the new facts and the `research` output; same artifact link.
- journey: rerun the kit; only unsent follow-ups change and are labelled "Updated"; sent ones stay byte-for-byte.
- quote: rerun the module suggestion.
Then `save_output` each as a draft with the new `V`.

## How sales-journey reads a lead (draft, for its owner to adopt)
Replace `research.md` and the local `lead.json` profile with `get_lead {slug}` (or `GET /api/v1/leads/<slug>` with a `read` token): use `profile` for `{industry, size, location, regulatory, risks}` and `record.version` as `inputs.lead`. The sales-entered fields (`current_system`, `users`, `departments`, …) become facts through `add_facts` instead of living only in the page.
