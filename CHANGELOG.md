# Changelog

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
