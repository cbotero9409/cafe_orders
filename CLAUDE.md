# Project rules

## Keep project docs in sync

With every big change, before every commit, and whenever else it is warranted, update:

- `to_do.txt`: check off finished items, add new tasks that came up.
- `PROJECT_STATUS.md`: reflect what is now done, in progress, and next.
- `README.md`: only if the change affects setup, usage, endpoints, or anything else documented there.

Include these doc updates in the same commit as the change they describe.

Before each commit, check every `to_do.txt` item against the diff, including CI, config, and tooling changes. Remove items that are fully done and reword items that are partly done.

## Priority

API/backend first, web pages after (reuse the same services).
