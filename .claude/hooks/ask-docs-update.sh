#!/usr/bin/env bash
# Before commit / PR / merge, stop when code changed but to_do.md / PROJECT_STATUS.md
# did not, so Claude asks the user in chat first. Asks once per set of code changes:
# a retry, or a PR / merge of the same changes, goes through; new code changes ask again.
cmd=$(jq -r '.tool_input.command // ""')
echo "$cmd" | grep -qE '\b(git commit|git merge|gh pr create|gh pr merge)\b' || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
base=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null || echo HEAD)

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

marker=$(git rev-parse --git-path "claude-docs-asked-${branch//\//_}")
fingerprint=$(git diff --cached "$base" -- app config db lib spec 'Gemfile*' | sha1sum | cut -d' ' -f1)
[ "$(cat "$marker" 2>/dev/null)" = "$fingerprint" ] && exit 0
echo "$fingerprint" > "$marker"

jq -n '{hookSpecificOutput: {
  hookEventName: "PreToolUse",
  permissionDecision: "deny",
  permissionDecisionReason: "Docs check (project hook): code changed on this branch but to_do.md / PROJECT_STATUS.md were not updated. Before retrying, ask the user with AskUserQuestion whether to update to_do.md, PROJECT_STATUS.md and README.md (README only if setup, usage or endpoints changed) or continue without them. Then do what they chose and retry the command; this hook will not stop it again for these same code changes."
}}'
