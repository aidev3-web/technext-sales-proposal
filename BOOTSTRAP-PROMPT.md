# Bootstrap prompt

Give the block below to a fresh session of your coding agent (Claude Code, Codex,
OpenCode, GitHub Copilot CLI, Gemini CLI, ...) **on the machine where the skill should
be installed**. The agent installs the skill into its own skills directory and verifies
the result. Replace the `<...>` placeholders before sending.

The same text is all a new machine needs - there is no other setup step.

---

```text
You are setting up the "technext-sales-proposal" Agent Skill on this machine.

Repository: https://github.com/aidev3-web/technext-sales-proposal   (private)
You need read access to it. If cloning fails with an authentication error, STOP and
tell me which of these I should do:
  (a) run `gh auth login` and retry,
  (b) give you a personal access token to use,
  (c) send me the repository as an archive instead.
Do not try to work around an auth error, and do not try to make the repository public.

Do this in order. Stop and ask me if anything is ambiguous.

1. Detect where YOUR host keeps Agent Skills - the directory that already contains
   <name>/SKILL.md. Likely candidates:
     ~/.claude/skills        ~/.codex/skills       ~/.config/opencode/skills
     ~/.gemini/skills        ~/.copilot/skills     ~/.cursor/skills
   Show me which ones exist and which one you will use. If more than one exists, ask
   me which to install into - do NOT install into all of them on your own.

2. Clone the repository somewhere OUTSIDE that skills directory (for example
   ~/technext-sales-proposal) and check out the newest v1.0.0-or-later tag.

3. Install it with the repository's own installer, pointing it at the directory from
   step 1:
     Windows     : pwsh -File install.ps1 -Destination "<skills dir from step 1>"
     macOS/Linux : ./install.sh --dest "<skills dir from step 1>"
   Add -Copy (Windows) or --copy (macOS/Linux) if symlinks are unavailable on this
   machine. The installer never overwrites an existing real folder; if it reports one,
   show me the message and ask before doing anything else.

4. Verify, and show me the raw output of each check:
   - the orchestrator skill and all 10 sub-skills are present in the skills directory
     (the installer prints one line per item)
   - <skills-dir>/technext-sales-proposal/SKILL.md is readable, and its frontmatter
     contains `name: technext-sales-proposal`
   - `python --version` - the pipeline needs Python 3.9 or newer
   - `node --version` and whether `npx ccusage` runs - optional, used only for the
     per-task cost report; the pipeline works without it

5. Report back in exactly this shape:
   - skills directory used:
   - tag / commit installed:
   - sub-skills linked (n of 10):
   - Python version:
   - cost report available (yes/no, and why):
   - anything the installer skipped, and why:
   - the exact thing I should type in this agent to invoke the skill:

Do not modify the skill's contents. If you think something should change, tell me
instead of editing it.
```

## After it finishes

Ask the agent for a proposal to prove the install works end to end:

```text
Research <company name> (<website>) and build a TechNext sales proposal for them.
```

Everything the run produces lands in `_runs/<client-slug>/`.

## Note on invoking the skill

The **content** of a skill is portable - `SKILL.md` and the Python helpers work under
any agent. How you *start* it is host-specific:

| Host | How to invoke |
|---|---|
| Claude Code | Type `/` and pick the skill, or type `/technext-sales-proposal` |
| Codex, OpenCode, Copilot CLI, Gemini CLI | Ask for it in plain language, e.g. "build a TechNext sales proposal for <client>" |

If your host exposes skills through a slash command, the name is the folder name:
`technext-sales-proposal`.
