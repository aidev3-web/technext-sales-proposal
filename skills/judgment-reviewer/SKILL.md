---
name: judgment-reviewer
description: Judgment-based review pass over an assembled sales-proposal HTML — citation-content spot-check, devil's-advocate review of the architecture/roadmap/recommendations, thin-section detection — then reports the run's real Claude token/cost via ccusage. Called by the technext-sales-proposal orchestrator skill after mechanical-validator passes, as the final step before delivery.
---

# Judgment reviewer — the checks a script can't do, then a cost report

*Only `<client-slug>-proposal.html` needs to exist — safe to re-run any time (e.g.
right after a manual fix) without touching earlier phases.*

This is a judgment-based review pass over the assembled file — a `fork` works well
here since it benefits from this conversation's full context of what was researched.
`mechanical-validator` already confirmed the objectively-countable stuff (no orphaned
citations, right chart/diagram counts, no leftover placeholders) — this pass checks
what still requires reading and judging content, not just counting it.

## Content review

- Every section has real, specific content — grep the file for `placeholder-note` or
  generic filler phrases; there should be none left.
- Every visible string has both a `t-vi` and a `t-en` span filled in — spot-check
  several sections, not just the first few.
- Any section that reads thin (a couple of generic sentences instead of grounded
  detail) gets re-sent to its owning Phase 1 subagent with a "go deeper, more specific
  to this client" instruction — don't pad thin sections by hand with filler.
- Cross-check internal consistency: the pain-solution matrix's module/AI choices
  should match what `research-ops-tech-agent` actually found; the quotation should
  match that same module plan's scope.

## Citation content check

The mechanical validator already confirmed the *links* aren't orphaned — this checks
whether they're actually right. Spot-check a sample of cited pages and confirm each
one really supports the claim it's attached to, don't just trust that a URL resolves.
Any sentence stating a specific fact (a number, a date, a quote, a review, a named
person) with neither a `.cite` link nor an `.assess` tag is a gap — go back to the
owning subagent and either find the source or mark it as an assessment.

If Phase 0 had meeting notes/transcript pasted in: confirm every fact actually stated
there made it in with a `.grade.confirmed` badge (not silently downgraded to
`.assess`), and every topic the notes *raised but didn't answer* has an explicit
`.callout warn` "to confirm" note rather than being quietly dropped.

## Devil's-advocate review

Before calling the proposal done, argue against the `recommendations` section and the
BPMN·Blueprint·UML process specifically — the parts a real client's IT lead or ops
manager would push back on hardest: Is any recommended module choice unjustified by
the actual pain points found? Does the recommended plan assume dependencies that were
never confirmed (e.g. data export access from a legacy system nobody verified
exists)? Fix what a skeptical reader would flag, rather than presenting the first
draft as final.

## Cost report — run after the content review, every time

Once the review above is done and the proposal is ready to hand over, run:
```
npx ccusage@latest
```
via `Bash`. This reads Claude Code's local session logs and prints the real token/cost
breakdown for this run — no API key, no account, no network call. Include this
report's numbers in your summary to the user (e.g. *"Chạy xong hết pipeline, ccusage
báo chi phí session này là $X, chủ yếu Y token Sonnet"*) so cost stays visible per run,
not something they have to check separately. If `ccusage` isn't available (no `npx`/no
Node on the machine), say so plainly and skip — don't block delivery on it, it's a
reporting step, not a gate.
