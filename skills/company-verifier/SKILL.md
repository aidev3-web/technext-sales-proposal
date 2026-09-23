---
name: company-verifier
description: Confirms the exact legal identity of a prospective client before any research spends effort — legal name, official domain, country, active status — using GLEIF's free public LEI API. Called by the technext-sales-proposal orchestrator skill's Phase 0, right after the client name/website is collected and before any of the 4 research subagents are dispatched.
---

# Company verifier — confirm the right company via GLEIF, free, no signup

## What this solves

Many company names collide across industries and countries. Spending 4 parallel
subagents' worth of research effort on the wrong company (or a company with the same
name in the wrong country) wastes the whole run. This skill does one cheap, mechanical
check first: resolve the given name/domain to a real registered legal entity via
GLEIF's [Global LEI Index](https://www.gleif.org/) before anything else starts.

**No account, no API key, no cost.** GLEIF's own API is free, unlimited for
reasonable use, and requires no registration — rate-limited at 60 requests/minute per
user, which this skill never comes close to (one lookup per client).

## What to do

Given the client name (and website, if the user already provided one):

1. **Call the GLEIF API directly** via `WebFetch` or `Bash curl` — use the **fulltext**
   filter, not `entity.legalName`:
   ```
   curl -s "https://api.gleif.org/api/v1/lei-records?filter[fulltext]=<COMPANY NAME>"
   ```
   **Do not use `filter[entity.legalName]=...`** — that param requires an almost
   exact string match and silently returns zero results for anything slightly off
   even when the company is really in the registry.

   **`filter[fulltext]` is still word-exact, not fuzzy** — tested directly against
   a real entity ("JRTech Solutions Inc.", Canada): a hyphen is treated as a space
   (`JR-Tech` and `JR Tech` both return the same broad set), but singular/plural and
   compound-vs-split spelling are NOT auto-corrected — `JRTech` (compound) and
   `JRTech Solutions` (compound + correct plural) both find it, while
   `JR Tech Solution` (split + singular) returns zero. **Don't stop at zero results
   from one query shape.** Before concluding "not in GLEIF": try the name as one
   compound word (strip spaces/hyphens entirely), try it plural and singular, and
   try just the most distinctive single word alone (drop generic words like
   "Solution"/"Group"/"Company" and legal suffixes like "Inc."/"Sdn Bhd") — then
   filter the (likely broader) result set yourself by country/address to find the
   real match, rather than trusting any single query's exact wording.
   If a website/domain is already known, prefer resolving by name first (GLEIF's
   index is keyed on legal name, not domain — there is no domain-to-LEI endpoint on
   the free public API, so a domain alone isn't directly searchable; use it only to
   help you judge which returned candidate is the right one).
2. **Read the response.** Each match returns `entity.legalName`, `entity.legalAddress`
   (country/city), `entity.status` (`ACTIVE`/`INACTIVE`), the LEI code itself, and
   registration authority details.
3. **Only accept a match when the legal name matches after normalization** (case,
   punctuation, legal suffixes like "Sdn Bhd"/"Pte Ltd"/"LLC" — don't require an exact
   byte-for-byte string match, but don't accept a loose/partial name match either). If
   nothing matches confidently, **that is a valid, expected outcome for most SMEs** —
   GLEIF's registry mostly covers larger/regulated entities, not small local
   businesses. Don't treat "no LEI found" as an error.
4. **If GLEIF finds a confident match**: write `company-identity.json` —
   `{ "legalName": "...", "country": "...", "city": "...", "status": "ACTIVE", "lei": "...", "source": "GLEIF", "confidence": "confirmed" }`
   — and use this as the `Confirmed`-grade legal-name/country facts for the
   `company-profile`/`due-diligence` sections (Phase 1's `research-due-diligence-agent`
   reads this file, doesn't need to re-verify these specific fields itself).
5. **If GLEIF finds no confident match** (the common case for SMEs): write
   `company-identity.json` with `"source": "web-search"` and `"confidence": "unverified"`
   instead, and fall through to the existing disambiguation approach —
   legal/trading name, country/city, industry, and a registration number or official
   domain found via ordinary web search, same as before this skill existed. Say so
   plainly to the user rather than silently treating a web-search guess as GLEIF-grade.

## Output

One file, `company-identity.json`, in either of the two shapes above. This is what
Phase 1's disambiguation gate now reads first (instead of redoing this reasoning from
scratch) — if two candidates are still plausible after this, still ask the user rather
than silently picking one.
