# TechNext sales-proposal skill

Turn a prospective client - a company name, a website, or a short brief - into one
comprehensive, bilingual (VI/EN) sales-proposal website covering all three TechNext
service lines:

- **Odoo ERP implementation**
- **AI Solutions**
- **Social Media Marketing**

The main output is a single self-contained HTML file (all CSS, JS and charts inlined,
no CDN) that opens correctly over `file://` with no network connection. Alongside it
the run produces a machine-readable findings JSON, a companion PWA bundle, a per-task
cost CSV, and a cost dashboard.

> **Proprietary software.** See [`LICENSE`](LICENSE). This repository is shared with
> named collaborators only. Do not redistribute, publish, or share it outside TechNext
> without written permission.

## Requirements

| Need | Why | Notes |
|---|---|---|
| An agentic coding tool that supports Agent Skills | Runs the skill | Claude Code, Codex, OpenCode, GitHub Copilot CLI, Gemini CLI. See [Agent support](#agent-support). |
| Python 3.9+ | Validation, citation binding, fragment stitching, cost reporting | Standard library only. `html5lib`, `beautifulsoup4` and `trafilatura` are optional and only improve parsing quality. |
| Node.js 18+ | `npx ccusage` for per-task cost reporting | Optional - the pipeline runs without it; only the cost report is skipped. |
| Internet access | Client research | [Jina Reader](https://r.jina.ai) (`r.jina.ai`) needs no API key. |

No API keys are required. The entity lookups use free, public sources: GLEIF,
Wikidata, Companies House, OpenCorporates and SEC EDGAR.

## Install

Clone this repository next to - not inside - your agent's skills directory, then run
the installer for your platform:

```powershell
git clone https://github.com/aidev3-web/technext-sales-proposal.git
cd technext-sales-proposal
pwsh -File install.ps1                 # Windows
```

```bash
git clone https://github.com/aidev3-web/technext-sales-proposal.git
cd technext-sales-proposal
./install.sh                           # macOS / Linux
```

The installer links the orchestrator skill **and** its 10 sub-skills into the agent
skills directory you choose, because the pipeline dispatches the sub-skills by name.
Use `--copy` (`-Copy` on Windows) if your filesystem does not support symlinks.

See [`QUICKSTART.md`](QUICKSTART.md) for the 5-step version, or hand
[`BOOTSTRAP-PROMPT.md`](BOOTSTRAP-PROMPT.md) to a new machine - the agent there
installs the skill into itself and reports back.

## Usage

Once installed, ask your agent for a proposal. For example:

```text
Research <company> (<website>) and build a TechNext sales proposal for them.
```

or, in Vietnamese:

```text
Làm sales proposal cho <công ty>, website <website>.
```

The orchestrator resolves the client's legal entity first, then runs the pipeline.
It writes its working files into a `_runs/<client-slug>/` folder next to your working
directory and produces the deliverables described below.

## What a run produces

| Output | File | Produced by |
|---|---|---|
| Bilingual sales proposal | `<client-slug>-proposal.html` | `assembler` |
| Machine-readable findings | `<client-slug>-findings.json` | research agents + `source-auditor` |
| Installable PWA bundle | `manifest.webmanifest` + `sw.js` + icons | `assembler` |
| Per-task cost report | `<client-slug>-cost-report.csv` | `judgment-reviewer` (`ccusage`) |
| Cost dashboard | `cost-dashboard.html` | Built once, reused for every run |

## How it works

One orchestrator drives the run:

1. **Intake and verification** - resolve the exact legal entity (GLEIF), look up
   officers from official registries, scan the client's own site and socials.
2. **Competitor research** - one `competitor-research-worker` per competitor, on a hard
   fetch/time budget, gated by a facts-only check before anything else runs.
3. **Research fan-out** - 4 parallel research sub-agents, one per section group.
4. **Assembly and validation** - source audit, chart manifest, assembly, 13 mechanical
   checks, then a judgment review and the per-task cost report.

## Repository layout

```text
SKILL.md                     Orchestrator map - start here
agents/                      5 sub-agent definitions
skills/                      10 sub-skills the pipeline dispatches
assets/                      Templates, research rules, validators, PWA files
api/  blocker/               Small helper pages and answer files
report/                      Internal design and review documents
index.html                   Internal dashboard linking the documents above
```

## Agent support

The skill is written to be agent-agnostic. Sub-agent definitions carry `tools:` and
`model:` frontmatter, which is the Claude Code convention; under another agent those
fields are simply ignored and you re-express the agent's toolset in whatever mechanism
that tool provides (or run that group's research directly). Everything else in the
skill is plain Markdown and Python.

## Versioning

See [`CHANGELOG.md`](CHANGELOG.md). Releases are tagged in this repository - pin to a
tag rather than following `main` if you need a stable version.

## Support

Contact TechNext Asia. When reporting a problem, include the client slug of the run and
the `_runs/<client-slug>/` folder if you can share it.
