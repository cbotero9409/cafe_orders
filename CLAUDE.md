# Project rules

## Keep project docs in sync

With every big change, before every commit, and whenever else it is warranted, update:

- `to_do.md`: check off finished items, add new tasks that came up.
- `PROJECT_STATUS.md`: reflect what is now done, in progress, and next.
- `README.md`: only if the change affects setup, usage, endpoints, or anything else documented there.

Include these doc updates in the same commit as the change they describe.

Before each commit, check every `to_do.md` item against the diff, including CI, config, and tooling changes. Remove items that are fully done and reword items that are partly done.

## Code review subagent

Run the rails-reviewer subagent only when asked, not before every commit. When asked, handle what it finds. For critical backend changes (services, models, migrations, auth, money), run it with `model: opus`.

## CI results

After pushing or opening a PR, wait for CI and report the result of each check. If a check fails, say whether the failure is new or already known (e.g. listed in `to_do.md`), and ask before merging on a new failure.

## Priority

API/backend first, web pages after (reuse the same services).
