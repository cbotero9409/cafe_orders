#!/usr/bin/env bash
# Before commit / PR / merge, stop when code changed but neither to_do.md nor
# PROJECT_STATUS.md did (in the commit itself, or on the branch for a PR or merge),
# so Claude asks the user in chat first. Nothing is recorded
# until the user agrees to continue (Claude retries with DOCS_ACK=1); after that, a
# retry, PR or merge of the same code changes goes through, and new changes ask again.
cmd=$(jq -r '.tool_input.command // ""')
echo "$cmd" | grep -qE '\bgit( -C \S+)? (commit|merge)(\s|$)|\bgh pr (create|merge)(\s|$)' || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
# A commit is checked on its own changes (an amend includes the commit it replaces);
# a PR or merge is checked on the whole branch.
if echo "$cmd" | grep -qE '\bgit( -C \S+)? commit(\s|$)'; then
  base=HEAD
  echo "$cmd" | grep -qE '\s--amend(\s|$)' && base=$(git rev-parse -q --verify HEAD~1 || echo HEAD)
else
  base=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null || echo HEAD)
fi

# Snapshot the whole working tree (committed, staged, unstaged, untracked) in a throwaway
# index, so the result doesn't depend on what is staged or already committed.
tmp_index=$(mktemp)
trap 'rm -f "$tmp_index"' EXIT
cp "$(git rev-parse --git-path index)" "$tmp_index"
export GIT_INDEX_FILE=$tmp_index
git add -A

changed=$(git diff --cached --name-only "$base")
echo "$changed" | grep -qE '^(app|config|db|lib|spec)/|^Gemfile' || exit 0
echo "$changed" | grep -qE '^(to_do|PROJECT_STATUS)\.md$' && exit 0

marker="$(git rev-parse --absolute-git-dir)/claude-docs-asked-${branch//\//_}"
fingerprint=$(git diff --cached "$base" -- app config db lib spec 'Gemfile*' | sha1sum | cut -d' ' -f1)
[ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ] && exit 0

if echo "$cmd" | grep -qE '(^|\s)DOCS_ACK=1\s'; then
  echo "$fingerprint" > "$marker"
  exit 0
fi

jq -n '{hookSpecificOutput: {
  hookEventName: "PreToolUse",
  permissionDecision: "deny",
  permissionDecisionReason: "Docs check (project hook): code changed but neither to_do.md nor PROJECT_STATUS.md was updated (in this commit, or on this branch for a PR or merge). Ask the user with AskUserQuestion whether to update to_do.md, PROJECT_STATUS.md and README.md first (README only if setup, usage or endpoints changed), continue without them, or not proceed. Update first: make the edits, then retry the command. Continue: retry the command prefixed with DOCS_ACK=1 (only after the user chose this). Not proceed: do nothing; the hook will ask again next time."
}}'
