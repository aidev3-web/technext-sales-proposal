# Charts & diagrams — required, not optional

Read this before Phase 1 (research subagents) or Phase 2 (front-matter) build any
chart/diagram.

Trung's original reference build (`full1`, Client Nova) is not just tables and
prose — it has **21 Chart.js canvas charts** and **9 process/flow diagrams** (rebuilt as
static HTML, not Mermaid — see below), styled
consistently (theme-aware grid/legend colors, a shared color palette, re-rendered on
light/dark toggle). A proposal with zero, or with charts that look like bare
default-styled Chart.js output, is missing a real part of the deliverable — an earlier
real run of this skill shipped with none at all, and a later one shipped a handful that
didn't match the reference's look.

**Use the real helper functions, don't hand-roll chart configs.**
`assets/proposal-template.html` now ports these **verbatim from `full1`** — every chart
must be built through them, never via a bare `new Chart(el, {...})` call, so it
automatically gets the right colors and survives the light/dark theme toggle:
```js
regChart(() => mkChart('cSentiment', {
  type: 'bar',
  data: {
    labels: ['5★','4★','3★','2★','1★'],
    datasets: [{ label: 'Share of reviews (est. %)', data: [72,18,6,2,2], backgroundColor: PAL, borderRadius: 6 }]
  },
  options: baseOpts({ scales: gridScale(), plugins: { legend: { display: false } } })
}));
```
- `regChart(fn)` registers the chart-builder so it (re-)runs on load **and** whenever
  `toggleTheme()` fires (`reRenderCharts()` destroys and rebuilds every registered
  chart) — a chart built with a bare `new Chart(...)` call outside `regChart(...)`
  will look wrong after a theme switch. Always wrap in `regChart(() => mkChart(...))`.
- `PAL` is the shared 10-color palette (`#19c6c6`, `#3b82f6`, `#6366f1`, `#ffb454`,
  `#ff6b6b`, `#36d399`, `#a78bfa`, `#f472b6`, `#37e0c8`, `#7eb0ff`) — use it for
  multi-category datasets (doughnut slices, grouped bars) instead of inventing new
  colors per chart.
- `baseOpts(extra)` sets `responsive`/`maintainAspectRatio`/theme-aware legend text
  color; merge your own `scales`/`plugins` into it via the `extra` argument rather than
  writing `options` from scratch.
- `gridScale(stacked?)` gives theme-aware x/y grid+tick colors for bar/line charts —
  use it for any chart with cartesian axes.
- `inkColors()` returns the current theme's `{grid, tick, ink}` — needed directly for
  radar (`scales.r`) configs, which `gridScale()` doesn't cover.
- **Chart labels/dataset labels are always plain strings, never HTML.** Chart.js
  renders them as plain canvas text, not HTML — `'<span class="t-vi">Facebook</span>
  <span class="t-en">Facebook</span>'` as a label literally prints the tag markup on
  the chart, it doesn't toggle with VI/EN like the rest of the page (a real run once
  did exactly this). Charts don't support the bilingual toggle — use a single combined
  string instead, e.g. `'Trực tiếp/Direct'` or just the term if it's the same in both
  languages (`'Facebook'`, `'Analytics'`).
- **Tooltips on any chart plotting percentages must say so.** Chart.js's default
  tooltip shows a bare number (`"25"`) with no unit — a real reader hovering has no
  idea if that's a percent, a count, or a score. Any chart whose `data` values are
  percentages (most doughnut/pie charts here — `cRevMix`, `cChannel`, `cOrigin`, etc.)
  needs a tooltip callback that appends the unit, e.g.:
  ```js
  plugins: { tooltip: { callbacks: { label: (ctx) => ` ${ctx.label}: ${ctx.parsed}%` } } }
  ```
  merge this into the chart's `plugins` alongside `legend`, same pattern as `baseOpts`.

**Full chart manifest — all 18, not a representative sample.** `full1` has 21 named
charts; this skill drops the 2 tied to the removed PESTLE/Porter's Five Forces
sections and 1 (`cAuto`) tied to the section removals below, leaving 18 required.
Content adapted per client's
actual industry, counts/labels never invented from nothing — an `.assess`-labeled
illustrative estimate is fine, an empty/missing chart is not). Each row below is one
required `<canvas id="...">`, its Chart.js `type`, which group writes it, and what it
shows (adapt the specific framing to the client's actual business — e.g. `cSeason`
becomes whatever this client's real demand-cycle driver is, not literally diving
season, if the client isn't a dive resort):

| Canvas id | Type | Owner | Shows |
|---|---|---|---|
| `cRevMix` | doughnut | Phase 2 (`exec-summary`) | Illustrative revenue/effort mix across the 3 proposed service lines |
| `cScorecard` | bar | Phase 2 (`exec-summary`) | Today vs. 12-months-post-engagement, indexed to 100 |
| `cRevStream` | bar (horizontal) | Group A (`company-profile`/`due-diligence`) | Revenue or activity share by product/service line |
| `cHeadcount` | bar | Group A (`staff-org`) | Estimated headcount by department |
| `cSeasonStaff` | line (dual-axis) | Group A (`staff-org`) | Staffing level vs. demand-cycle driver over the year |
| `cChannel` | doughnut | Group A (`digital-web`) | Acquisition/inquiry channel mix |
| `cDigital` | radar | Group A (`digital-web`) | Digital maturity today vs. post-engagement target |
| `cSentiment` | bar | Group A (`reviews-reputation`) | Review star-rating distribution |
| `cThemes` | bar (stacked) | Group A (`reviews-reputation`) | Recurring praise vs. complaint themes |
| `cPosition` | bubble | Group A (`competitor-deep-dive`) | Positioning map — price vs. rating, bubble ≈ scale |
| `cGap` | radar | Group A (`competitor-deep-dive`) | Feature-gap vs. premium peers |
| `cOrigin` | doughnut | Group A (`market-industry`) | Customer origin/segment mix |
| `cSeason` | line | Group A (`market-industry`) | Demand-cycle curve for this client's actual industry |
| `cPersona` | bubble | Group A (`customer-personas`) | CLV & volume by persona, bubble = share |
| `cOwner` | bubble | Group C (`advisory`) | The major recommended decisions — impact vs. effort |
| `cRisk` | bubble | Phase 2 (`recommendations`) | Risk highlights — probability × impact, bubble = urgency |
| `cKpi` | bar | Phase 2 (`recommendations`) | Recommended baseline vs. 12-month target per KPI |
| `cRoi` | line | Phase 2 (`recommendations`) | Recommended cumulative cost vs. cumulative benefit, break-even visible |

That's **12 charts for Group A, 1 for Group C (`cOwner`), 2 for Phase 2's `exec-summary`,
3 for Phase 2's new `recommendations` section** = 18 total. `cAuto` and the old
Group B/C ownership were retired along with the sections they belonged to — see
"Removed sections" below. Group A owning most of them is expected — it's chart-config
generation from research Group A already did, not new research, so it doesn't need
extra research time.

**Removed sections — boss feedback 2026-09-23.** The boss explicitly asked to remove
these 12 sections (see the removal list in `assets/menu-structure.md`): `operations`,
`stakeholder-perspectives`, `ai-automation-catalog`, `ai-in-action`,
`odoo-architecture`, `data-migration`, `social-media-architecture`,
`implementation-roadmap`, `change-management`, `hypercare-support`,
`risk-register-raci`, `kpis-benefits`. **Do not generate these sections or their
`<section id="...">` blocks — they no longer exist in `assets/menu-structure.md` and
must not be added back.** Their forward-looking numbers (risk, KPI targets, ROI) now
live in the new `recommendations` section (Phase 2) instead of being spread
across the deleted delivery-mechanics sections.

**Full diagram manifest — 4, no Mermaid.** Boss feedback 2026-09-23: *"Do not use
mermaid chart."* Every diagram slot below is built as **static HTML using the
template's own component classes**, never `<div class="mermaid">`/Mermaid syntax —
this also settles the BPMN·Blueprint·UML section's fate: it stays (it wasn't on the
removal list), just rebuilt without Mermaid. 5 of the original 9 slots were owned by
sections now removed (module-dependency, integration-map, migration cutover, roadmap
timeline, hypercare triage) and are dropped, not reassigned.

| # | Static shape | Owner | Shows |
|---|---|---|---|
| 1 | `.tl` timeline (vertical) | Group A (`staff-org`) | Organisation chart / reporting lines — render as a nested `.tl` (manager → reports) or a `.grid.g3` of role `.card`s with a "reports to" line, not a literal org-chart image |
| 2 | numbered `.tl` steps | Group B (`department-workflows`) | Acquisition funnel / manual-handling load, as-is — one `.tl` step per stage with a volume/drop-off note |
| 3 | `.tl` swimlane-by-role | Group B (`bpmn-blueprint-uml`) | BPMN-style process — one `.tl` per role/lane (labelled), steps in sequence, the client's core operational process as-is → to-be |
| 4 | numbered `.tl` sequence | Group B (`bpmn-blueprint-uml`) | UML-style sequence — a key transaction flow (e.g. order → fulfillment → invoice) as ordered steps, actor named per step |

That's **1 for Group A, 3 for Group B** = 4 total. Group C and Group D (Tools &
Documents) don't own any required diagram in this manifest. Give each of these 4 a
`<div class="diagram-block" data-diagram="N">` wrapper (any real content inside is
fine — `.tl`/`.tbl`/`.quad`/`.acc` — the wrapper is just what Phase 4's validator
counts) so the mechanical check can confirm all 4 are present without depending on any
one specific inner markup shape.

Each `<canvas id="...">` above must appear in the HTML with that exact id and exactly
one matching `regChart(() => mkChart('...', {...}))` call in a `<script>` block placed
right after that section's HTML (or batched at the end of `<main>` — either is fine as
long as every canvas gets registered). Phase 4's mechanical validator (check #9) checks
for all 18 canvases (by exact id) and all 4 `diagram-block` wrappers by count — missing
several is a fail, not a warning.
