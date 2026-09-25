# Changelog

All notable changes to this skill are documented here.
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
