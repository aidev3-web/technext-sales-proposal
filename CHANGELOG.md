# Changelog

## [Unreleased]

### Added
- **"What's updated" change log in the template.** The floating popup switches from "Read before
  the meeting" to a change log once `#changelog-data` has entries (newest first, each item links
  to the section it changed, new / changed / removed, red dot until the reader opens it, last-seen
  remembered in `localStorage`). An empty list leaves the original popup untouched. It came from
  the Hitachi run, where it had been added by hand, and was never in the template.
- **`.g5-flow` five-step flow component** (also from the Hitachi run), documented in `section-shell.md`.
- **`validate-proposal.py` check 16:** the change log must be valid JSON with real section ids,
  kinds new/changed/removed and vi + en text; proposals from an older template are skipped.

## [1.1.2] - 2026-09-25

### Fixed
- `SKILL.md` still described `validate-proposal.py` as having 13 hard checks after
  v1.1.1 added check 14 (chart-render wiring). Now says 14.

## [1.1.1] - 2026-09-25

### Fixed
- **Charts could all render blank in a delivered proposal.** `section-shell.md` tells
  each sub-agent to emit `<script>regChart(() => mkChart(...))</script>` inside its own
  section, but `assets/proposal-template.html` defined `regChart`/`mkChart` in a script
  placed *after* all sections. Every registration therefore threw
  `ReferenceError: regChart is not defined` and **0 of 18 charts painted**, even though
  all 18 `<canvas>` elements were present ? this is what blanked the charts in a real
  delivered run. The chart framework (`chartDefs`, `regChart`, `inkColors`, `baseOpts`,
  `gridScale`, `mkChart`, `renderCharts`, `reRenderCharts`) now lives in its own
  `<script>` in `<head>`, above every section that registers a chart.
- A second, independent blank-chart cause: `cRevStream` built its options with
  `baseOpts({ scales:{...} + plugins:{...} })` ? `+` instead of `,` between object
  properties, a JS **syntax** error that stopped that whole `<script>` from running.
  Now a single valid object literal.
- The Vietnamese template footer still credited the old skill name
  `sales-proposal-skill`; it now says `technext-sales-proposal`.

### Added
- `assets/validate-proposal.py` check **14 ? "Charts are actually wired up"**: strips
  comments, collects `<canvas id>` and `mkChart('id')` pairs, requires `function
  regChart` to be defined *before* every `regChart(...)` call, and fails on canvases
  with no registration, registrations with no canvas, and option objects merged with
  `+`. The previous checks counted canvases/registrations but never noticed none of
  them rendered.

All notable changes to this skill are documented here.
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-25

### Added
- **Cost reporting now covers phases that run inline in the orchestrator's own
  session.** `checkpoint-manager` records that session's id with
  `"shared_session": true`, and `ccusage_to_csv.py` reports the session **once**,
  labelled `shared-session: <task> + <task>`. Previously those phases carried
  `session_id: null`, got no cost row at all, and the run total silently
  under-reported (a real run hid $0.4817 of $1.1150 that way).
- `SKILL.md` now states that every run writes its artefacts into `_runs/<client-slug>/`.

### Fixed
- `cost-dashboard.html` no longer reports tasks as having a missing cost row when they
  are covered by a `shared-session:` row.
- Brand spelling in deliverables: `Technext` -> `TechNext` in the proposal template,
  the PWA manifest and the `<title>` convention. The template footer also credited the
  old skill name `sales-proposal-skill`; it now says `technext-sales-proposal`.

## [1.0.1] - 2026-09-25

### Added
- `BOOTSTRAP-PROMPT.md` - a copy-paste prompt that lets a fresh agent on a new machine
  install this skill into its own skills directory and verify the result itself.

## [1.0.0] - 2026-09-25

First packaged release.

### Added
- `README.md`, `QUICKSTART.md`, `LICENSE` (proprietary) and this changelog.
- `install.ps1` / `install.sh` installers that link the orchestrator skill and its 10
  sub-skills into an agent's skills directory.
- `.gitattributes` so a fresh checkout keeps LF endings on every platform.
- Cost dashboard (`skills/judgment-reviewer/assets/cost-dashboard.html`): a single
  HTML file, built once, that loads any number of `*-cost-report.csv` files and shows
  a merged table with per-run subtotals and a grand total.

### Changed
- `ccusage_to_csv.py` now writes **CSV only** (the per-run HTML table is no longer
  generated on every run) - the dashboard above covers the visual view.
- Documentation is now agent-agnostic: hardcoded Claude-only paths, `WebFetch`-only
  fetch instructions and Claude model names were replaced with tool-neutral wording.
  The skill runs under any coding agent that supports Agent Skills.

### Removed
- The `demo/` folder (real client proposal outputs) is no longer part of the package.
- Real client names and a real session id were removed from all shipped documents.

### Fixed
- The pipeline diagram's Outputs panel now lists the cost CSV and the cost dashboard,
  its model labels no longer name Claude-only models, and the agent strip includes
  `competitor-research-worker`.
