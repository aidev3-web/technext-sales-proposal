---
name: web-osint-scanner
description: Reads and understands the verified client's official website end to end, and extracts every related link (social media profiles, review/listing sites, news mentions, partner/customer pages) so the 4 research subagents know exactly which pages to check instead of guessing. Also does a light mechanical scan of the site's tech stack/traffic signal. Called by the technext-sales-proposal orchestrator right after company-verifier confirms the client's identity, before the 4 research subagents are dispatched.
---

# Web OSINT scanner — read the site, pull out every related link

## What this solves

Before this skill existed, each of the 4 research subagents had to independently
guess which social media profile, review site, or news mention actually belongs to
the client — duplicating the same "is this really their Facebook page?" work 4 times,
inconsistently. This skill does that discovery **once**, up front, and hands every
subagent the same verified link list.

## What to do

Given `company-identity.json` (from `company-verifier`) — its confirmed domain:

1. **Read the site's actual content**, not just its tech signature. Use Firecrawl
   (if an API key is configured) or `WebFetch`/`Bash curl` otherwise, on the
   homepage plus any "About"/"Contact"/"Team" pages linked from it. This is reading
   for **understanding**, not just scraping raw HTML — summarize what the company
   actually does, in your own words, as a short paragraph (this becomes part of
   `web-scan.json`, saving the research subagents from re-reading the homepage from
   scratch).
2. **Extract every related link found on the site** — don't just take the footer's
   social icons at face value, also check for links buried in body text, the
   "Contact"/"Press"/"Team" pages, and any embedded widgets (an embedded Google
   Reviews widget, an embedded Instagram feed, etc. all count as a link source).
   Categorize what you find:
   - Social media profiles (Facebook, Instagram, LinkedIn, TikTok, X/Twitter, YouTube
     — whichever actually exist; don't invent ones that aren't linked)
   - Review/listing platforms (Google Business Profile, TripAdvisor, industry-specific
     directories)
   - News/press mentions (an actual "As featured in" link or press-page link — not a
     guess at what press *might* exist)
   - Partner/customer logos or case-study pages, if linked
3. **Light mechanical scan of the domain itself** (no judgment needed, just facts):
   tech stack/CMS in use if detectable from page source, roughly how long the domain
   has existed, whether it serves over HTTPS. Skip anything you can't determine
   directly — don't guess a tech stack from vibes.
4. **Write `web-scan.json`**:
   ```json
   {
     "summary": "One paragraph in your own words of what this company actually does",
     "links": {
       "social": [{ "platform": "facebook", "url": "..." }],
       "reviews": [{ "platform": "google", "url": "..." }],
       "press": ["..."],
       "other": ["..."]
     },
     "tech": { "cms": "...", "https": true, "domain_age_estimate": "..." }
   }
   ```
   Every entry in `links` must be a URL you actually found on the site — never invent
   a plausible-looking social handle. If a platform you'd expect (e.g. Instagram) has
   no link on the site, that's a real, useful finding (absence itself is data for
   `digital-web`'s "obvious gaps" callout) — record it as absent, don't search for one
   independently and guess it belongs to them.

## Output

One file, `web-scan.json`. The 4 research subagents read this before starting their
own web research — `research-due-diligence-agent` in particular should follow the
`links.social` and `links.reviews` entries directly instead of re-discovering them,
and use the `summary` as a starting point rather than re-reading the homepage cold.
