// Vercel serverless function: GET reads blocker/answers.json from the repo,
// POST { id, answer } merges one answer in and commits it back via the
// GitHub Contents API. Requires a GITHUB_TOKEN env var (repo scope) set in
// the Vercel project — ask Trung for setup steps (no written doc for this exists yet).

const OWNER = 'aidev3-web';
const REPO = 'technext-sales-proposal';
const FILE_PATH = 'blocker/answers.json';

async function readFile(token) {
  const r = await fetch(
    `https://api.github.com/repos/${OWNER}/${REPO}/contents/${FILE_PATH}`,
    { headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json' } }
  );
  if (r.status === 404) return { data: {}, sha: undefined };
  if (!r.ok) throw new Error('github_read_failed_' + r.status);
  const j = await r.json();
  const content = Buffer.from(j.content, 'base64').toString('utf-8');
  return { data: content ? JSON.parse(content) : {}, sha: j.sha };
}

module.exports = async (req, res) => {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    res.status(500).json({ error: 'missing_github_token', message: 'GITHUB_TOKEN env var is not set on this Vercel project.' });
    return;
  }

  if (req.method === 'GET') {
    try {
      const { data } = await readFile(token);
      res.status(200).json(data);
    } catch (e) {
      res.status(500).json({ error: 'read_failed', message: String(e) });
    }
    return;
  }

  if (req.method === 'POST') {
    try {
      const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
      const { id, answer } = body || {};
      if (!id || typeof answer !== 'string') {
        res.status(400).json({ error: 'bad_request' });
        return;
      }
      const { data, sha } = await readFile(token);
      data[id] = { answer, updatedAt: new Date().toISOString() };
      const newContent = Buffer.from(JSON.stringify(data, null, 2)).toString('base64');
      const putRes = await fetch(
        `https://api.github.com/repos/${OWNER}/${REPO}/contents/${FILE_PATH}`,
        {
          method: 'PUT',
          headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json' },
          body: JSON.stringify({
            message: `chore: blocker answer "${id}" updated`,
            content: newContent,
            sha,
          }),
        }
      );
      if (!putRes.ok) {
        const detail = await putRes.text();
        res.status(502).json({ error: 'write_failed', detail });
        return;
      }
      res.status(200).json({ ok: true });
    } catch (e) {
      res.status(500).json({ error: 'write_failed', message: String(e) });
    }
    return;
  }

  res.status(405).json({ error: 'method_not_allowed' });
};
