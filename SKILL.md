---
name: technext-sales-proposal
description: Turn a prospective TechNext client (a company name, website, or short brief) into one comprehensive, bilingual (VI/EN toggle) self-contained HTML sales proposal website covering all three TechNext service lines — Odoo ERP implementation, AI Solutions, and Social Media Marketing — deep web/social research, a fixed sidebar covering Due Diligence, Strategic Analysis (competitors/market), Operations, a Recommendations section, and a Tools & Documents section (AI Build Playbook, Profit Estimator, Quotation, Meeting Minutes, Discovery Questions, etc). Use when asked to research a client and build a sales proposal / due-diligence site, "làm sales proposal", "nghiên cứu khách hàng làm đề xuất", or when the request matches the client-research-to-proposal workflow (spin up agents, research a company, produce a growth plan with a big sidebar).
---

# Sales proposal skill — client research → TechNext sales proposal site (Odoo ERP · AI · Social Media)

**This file is the orchestrator's map, not the full instructions.** Each phase below
now lives in its own skill or subagent file — read the linked file when you actually
run that phase, don't try to hold the whole pipeline in this one file. This split
happened because the file had grown past 800 lines; each piece is now independently
readable, testable, and editable.

## What this is for

TechNext sells three service lines: **Odoo ERP implementation, AI Solutions, and
Social Media Marketing** — not just Odoo. Before pitching a prospective client, Trung
researches them thoroughly and produces one big HTML "site" that doubles as a
due-diligence report and a sales proposal: who the client is, their market and
competitors, and a concrete plan across all three TechNext service lines for them.

**Every proposal always pitches all three service lines**, grounded in this specific
client's own research, never a generic three-service pitch copy-pasted across clients.
Don't ask the user which service(s) to include — that decision was already made.

**Output**: exactly one self-contained `.html` file, `<client-slug>-proposal.html`,
with a fixed ~40-item sidebar (client-side JS nav, no page reloads), a VI/EN language
toggle, and a light/dark theme toggle.

**Every factual claim must be verifiable, not just plausible-sounding.** Any claim
from a real source gets a hover-card citation; any TechNext inference/estimate gets an
`.assess` tag. Never invent a number, quote, or named person with a fake-looking
citation. Full rules: `~/.claude/skills/technext-sales-proposal/assets/research-rules.md`.

## Reference map — read the linked file before doing that phase's work

| Phase | What it does | Read this |
|---|---|---|
| 0 — Intake | Get client identifier, disambiguate, ask about checkpoint resume | Below on this page |
| 0.5 — Company verification | Confirm the exact legal entity via GLEIF (free, no key) before research starts | Skill: `company-verifier` |
| Checkpointing | Decide which phase/group/section actually needs to run; resume logic | Skill: `checkpoint-manager` |
| 1 — Research fan-out | 4 parallel subagents, each researches + writes its own section group + charts | Agents: `research-due-diligence-agent`, `research-ops-tech-agent`, `research-delivery-growth-agent`, `tools-documents-agent` — shared rules in `assets/research-rules.md` |
| Charts & diagrams manifest | Exact canvas ids/diagram slots, ownership, the 2026-09-23 boss-feedback section removals | `assets/charts-and-diagrams.md` |
| Template/validator reference | The shell you must build from, the per-client palette rule, what `validate-proposal.py` checks | `assets/reference-files.md` |
| 2 — Front matter | Overview/Executive Summary/Recommendations/3 Proposed Solutions, written directly (no agent) | Skill: `front-matter-writer` |
| 3 — Assembly | Extract sections from Phase 1 previews, drop into the template in fixed order | Skill: `assembler` |
| 4a — Mechanical validation | Run `validate-proposal.py`'s 11 hard checks | Skill: `mechanical-validator` |
| 4b — Judgment review | Content/citation spot-check, devil's-advocate pass, then a `ccusage` cost report | Skill: `judgment-reviewer` |

## Phase 0 — Intake

Get the client identifier: company name, plus any URL/socials the user already gives,
and ask once for discovery-call notes/transcript if the user hasn't offered any
(*"Bạn có ghi chú/bản ghi/transcript nào từ buổi gọi hoặc họp với khách hàng này chưa?
Nếu có, dán vào đây."* — treat this as `Confirmed`-grade, higher trust than anything
web-researched). If all you have is a bare name, do one round of web search to find
their site/socials yourself rather than stopping to ask — only ask the user directly
if the name is too ambiguous to search confidently. Confirm the client name you'll use
in the page `<title>`: `"<Client> · Strategic Due Diligence & Growth Blueprint (Odoo ERP · AI · Social Media) · Technext"`.

Then run the `company-verifier` skill (GLEIF check), then the `checkpoint-manager`
skill (decide what actually needs to run this invocation — full pipeline, or resume
one phase/group/section) before dispatching anything else.

**Research depth.** Always a full "Standard" pass — there is no "Quick" mode. If a
client genuinely has very little public footprint, say so plainly in the relevant
sections rather than switching to a thinner research pass.

**Scope & ethics boundary.** Research stays limited to information a company and its
leadership have made public in a business capacity. Never pursue private/personal
information about individuals unrelated to their business role, and never use
non-public collection methods. If a request pushes past this line, decline that part
and say why.

## Delivery

Save as `<client-slug>-proposal.html` plus its companion `<client-slug>-findings.json`
and hand both to the user directly, along with the 4 PWA companion files
(`manifest.webmanifest`, `sw.js`, `icon-192.png`, `icon-512.png`) copied unchanged from
`assets/` — mention that the Install button only works if all four are deployed
alongside the HTML at a real static path, not when the HTML is opened alone via
`file://` (see `assets/reference-files.md`). Note in your summary which research areas
came back thin or unverifiable, and include `judgment-reviewer`'s `ccusage` cost
report for this run.

Once Phase 4 passes and the file is handed over, the `-p1-group*.html`,
`-p1-digests.json`, and `-p2-frontmatter.html` intermediate files are no longer needed
for a fresh run — but don't delete them automatically; ask the user first in case they
want to keep them for a future incremental re-run.

## Judgment calls

- **Client has very little public presence** (small/local business) — say so plainly
  rather than inventing specifics; keep every framework grounded in what's actually
  knowable, note assumptions explicitly.
- **User wants fewer sections for a quick draft** — you can trim scope if they
  explicitly ask, but the default always produces the full sidebar from
  `assets/menu-structure.md`.
- **Odoo version other than 19 mentioned** — ask; the fixed instruction set here
  assumes Odoo 19, but a client conversation may specify differently.
