---
name: technext-sales
description: The single entry point for TechNext sales work on the Proposal Portal. Claims open jobs from the portal queue (generate_all, ingest_notes, regenerate) and runs the generators — research, proposal, Sales Journey kit, draft quote — against ONE version of the lead record, then saves each output as a draft for an approver to publish. Use when the person says "chạy việc mới", "run new jobs", "có việc gì trên portal", "cập nhật lead từ ghi chú họp", or asks to generate the full set (proposal + journey + quote) for a lead created with the portal's New button. DRAFT — portal endpoints (P1/P2) are not live yet; see "Status".
---

# TechNext Sales — job runner (draft, P2)

Implements section 5.4/5.5 of `proposal-library/2026-11-05 Design – Một engine cho proposal, journey và báo giá.md`.
Code holds the contracts (`proposal-library/lib/lead.mjs`, `lib/journey.mjs`, `lib/adapters/findings.mjs`);
this skill only orchestrates and does the AI steps. Never bypass a validator to "make it pass".

## Status
Not runnable end-to-end yet. Missing on the portal side (owner: session/Trung, P1–P2):
`GET/POST /api/v1/leads`, `/facts`, `/outputs/<kind>`, `/jobs` and the write MCP tools
`list_jobs, claim_job, get_lead, add_facts, save_output, complete_job`. Until they exist, stop at step 1
and tell the person which endpoint is missing. Do not fall back to local folders as the source of truth.

## Hard rules (from the design, section 2)
1. The AI never writes a price. Quote = AI suggests modules with reasons; prices come from the costing code.
2. One research per lead. If the record already has a `research` output, do not research again — read it.
3. No customer phone number or email anywhere: facts, prompts, outputs. Strip them from notes before anything else.
4. Nothing goes on the card without an approver/admin: this skill only saves `draft`, it never calls publish.
5. A follow-up message already marked sent is never regenerated.
6. All generators in one run read the same `record.version`. Record that version in each output's `inputs.lead`.
7. Only the lead's `runner` runs its later jobs (artifacts can only be updated by whoever published them).

## Flow

### 1. Pick a job
`list_jobs` → show the person the open jobs (lead, kind, age) → `claim_job` the one they choose.
If the lead has a `runner` that is not this person, do not claim; say who the runner is.

### 2. Load the lead
`get_lead <slug>` → keep `record.version` as `V`, the computed `profile`, and `outputs`.

### 3. By job kind

**generate_all** (New button):
1. Research — run the `technext-sales-proposal` research phases (Phase 0 → Phase 1 → source-auditor),
   seeded from the form facts in the profile. Output: `audited-findings.json`.
2. Facts — `usableFindings(audited)` from `lib/adapters/findings.mjs`; follow the picks prompt
   (`proposal-library/docs/findings-picks-prompt.md`) to choose at most one pick per FACT_KEY with
   `from` = finding indices; `factsFromPicks(audited, picks, {by})`. Errors → fix the picks, never the findings.
   `add_facts` with the result, then `save_output research` (the full audited file). Reload: new `V`.
3. In parallel, all reading version `V`:
   - proposal: `technext-sales-proposal` writing/assembly/validation phases, inputs from the record. Publish the artifact (way A), `save_output proposal` with its URL.
   - journey: the `sales-journey` `kit.md` recipe with `profile` + `playbook.json` → `{kit, vars}`; check with `node lib/journey.mjs` before `save_output journey`.
   - quote: suggest `[{module, reason}]` only. If any of `package`, `users`, `addons` is missing from the profile, save the quote as "cannot calculate yet" with the missing keys listed. Label it "AI suggestion" unless a `modules` fact with `source.kind: neil` exists.
4. `complete_job`.

**ingest_notes** (pasted notes or a Gemini link):
1. Remove every phone number and email from the notes first.
2. Extract facts: `confirmed`, `source.kind` `call` or `meeting`, `source.ref` = the meeting label/date. Only FACT_KEYS. Use `supersedes` when a fact replaces an earlier one with the same key.
3. `add_facts`, then `complete_job`. The portal computes stale outputs and queues `regenerate`. Do not keep the raw notes anywhere.

**regenerate** (only stale outputs):
- proposal: update, do not rebuild — use `technext-meeting-to-proposal` with the new facts and the `research` output. Same artifact link.
- journey: rerun the kit; unsent follow-ups only, labelled "Updated"; sent ones stay byte-for-byte.
- quote: rerun the module suggestion if `modules/users/package/current_system` changed.
Then `save_output` each as `draft`, `complete_job`.

### 4. Hand back
One short summary to the person: which outputs are now drafts, any "cannot calculate yet" quote and its missing facts, and that an approver must publish on the portal.

## On failure
`fail_job` with a one-line reason (validator message, missing endpoint, research blocked). Never save a draft that failed its validator.
