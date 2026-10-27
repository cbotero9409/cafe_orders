#!/usr/bin/env bash
# Before commit / PR / merge, stop once per branch when code changed but
# to_do.md / PROJECT_STATUS.md did not, so Claude asks the user in chat first.
cmd=$(jq -r '.tool_input.command // ""')
echo "$cmd" | grep -qE '\b(git commit|git merge|gh pr create|gh pr merge)\b' || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
marker=$(git rev-parse --git-path "claude-docs-asked-${branch//\//_}")
[ -e "$marker" ] && exit 0

# Everything this branch touches: commits since main, plus staged, unstaged and untracked files.
base=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null)
changed=$(
  [ -n "$base" ] && git diff --name-only "$base" HEAD
  git diff --name-only HEAD 2>/dev/null
  git ls-files --others --exclude-standard
)

echo "$changed" | grep -qE '^(app|config|db|lib|spec)/|^Gemfile' || exit 0
echo "$changed" | grep -qE '^(to_do|PROJECT_STATUS)\.md$' && exit 0

touch "$marker"
jq -n '{hookSpecificOutput: {
  hookEventName: "PreToolUse",
  permissionDecision: "deny",
  permissionDecisionReason: "Docs check (project hook): code changed on this branch but to_do.md / PROJECT_STATUS.md were not updated. Before retrying, ask the user with AskUserQuestion whether to update to_do.md, PROJECT_STATUS.md and README.md (README only if setup, usage or endpoints changed) or continue without them. Then do what they chose and retry the command; this hook will not stop it again on this branch."
}}'
