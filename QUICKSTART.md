# Quickstart

Five steps from clone to first proposal.

1. **Clone**

   ```bash
   git clone https://github.com/aidev3-web/technext-sales-proposal.git
   cd technext-sales-proposal
   ```

2. **Install into your agent** (links the skill and its 10 sub-skills into the agent's
   skills directory; use `--copy` / `-Copy` where symlinks are unavailable)

   ```powershell
   pwsh -File install.ps1
   ```

   ```bash
   ./install.sh
   ```

3. **Check the prerequisites** - Python 3.9+ is needed for the validators. Node.js is
   only needed if you want the per-task cost report.

4. **Ask for a proposal** - in your agent:

   ```text
   Research Casa Anilao (https://example.com) and build a TechNext sales proposal.
   ```

5. **Collect the output** - everything lands in `_runs/<client-slug>/`:
   `<client-slug>-proposal.html` is the file you deliver to the client.

## If something fails

| Symptom | Fix |
|---|---|
| `validate-proposal.py` reports missing charts | The research phase returned fewer than 18 charts - re-run the affected group. |
| Cost report is empty | `npx ccusage` is unavailable or the agent writes logs somewhere `ccusage` cannot read. The pipeline does not need it. |
| A fetch returns a login or Cloudflare page | Use Jina Reader (`https://r.jina.ai/<url>`) instead of fetching directly. |
