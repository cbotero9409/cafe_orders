#!/usr/bin/env bash
# Before git commit, run RuboCop on the changed Ruby files (committed or not, so
# `git add ... && git commit` in one command is covered too).
# - No offenses: the commit goes through.
# - Safe Layout/Style offenses: autocorrected; Claude re-stages, reports the fixes in
#   chat and retries.
# - Anything else (Lint, Security, Rails, uncorrectable, errors) or an autocorrect that
#   deleted code: Claude asks the user first. Keeping them retries with RUBOCOP_ACK=1.
cmd=$(jq -r '.tool_input.command // ""')
echo "$cmd" | grep -qE '\bgit( -C \S+)? commit(\s|$)' || exit 0
echo "$cmd" | grep -qE '(^|\s)RUBOCOP_ACK=1\s' && exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
[ -x bin/rubocop ] || exit 0

ruby_re='(\.(rb|rake|gemspec|jbuilder|ru)|(^|/)(Gemfile|Rakefile))$'
mapfile -t files < <(
  { git diff --name-only --diff-filter=ACMR HEAD; git ls-files --others --exclude-standard; } |
    sort -u | grep -E "$ruby_re" | while read -r f; do [ -f "$f" ] && echo "$f"; done
)
[ ${#files[@]} -eq 0 ] && exit 0

# Format: "file:line Cop/Name: message", one per offense.
offenses() {
  bin/rubocop --force-exclusion --format json "$@" "${files[@]}" 2>/dev/null |
    jq -r '.files[] | .path as $p | .offenses[]
      | select(($ENV.ONLY_CORRECTED // "") == "" or .corrected)
      | "\($p):\(.location.start_line) \(.cop_name): \(.message)"'
}

before=$(offenses)
[ -z "$before" ] && exit 0

# Back up the files so an autocorrect the user rejects can be undone.
backup="$(git rev-parse --absolute-git-dir)/claude-rubocop-backup"
rm -rf "$backup" && mkdir -p "$backup"
for f in "${files[@]}"; do mkdir -p "$backup/$(dirname "$f")" && cp "$f" "$backup/$f"; done

corrected=$(ONLY_CORRECTED=1 offenses --autocorrect --only Layout,Style)
remaining=$(offenses)

# Autocorrect "deleted something" when a file lost more non-blank lines than it gained.
deleted=""
for f in "${files[@]}"; do
  cmp -s "$backup/$f" "$f" && continue
  d=$(diff "$backup/$f" "$f")
  removed=$(echo "$d" | grep -cE '^< .*\S')
  added=$(echo "$d" | grep -cE '^> .*\S')
  [ "$removed" -gt "$added" ] && deleted+="$f (-$removed/+$added non-blank lines)"$'\n'
done
changed_files=$(for f in "${files[@]}"; do cmp -s "$backup/$f" "$f" || echo "$f"; done)

if [ -z "$remaining" ] && [ -z "$deleted" ]; then
  reason="RuboCop check (project hook): autocorrected these offenses:
$corrected

Files changed: $(echo $changed_files)
The whole command was blocked, so nothing in it ran (including any git add). Re-run it with those files added too, after telling the user in chat which files and cops were corrected."
else
  reason="RuboCop check (project hook): found issues that need the user's decision. Do not fix them yet.
${remaining:+
Offenses not autocorrected (critical or unsafe to fix automatically):
$remaining
}${deleted:+
Safe autocorrect removed code in:
$deleted}${corrected:+
Autocorrected (already applied):
$corrected
}
Backups of the files before autocorrect: $backup/<path>.
The whole command was blocked, so nothing in it ran (including any git add); when retrying, re-run all of it.
Ask the user with AskUserQuestion, listing each issue with your proposed change, whether to: apply your proposed fixes, keep the code as is, or not commit. Fix: edit the files, re-stage and retry the commit. Keep: if they also reject the removed code, restore it from the backup; then re-stage and retry the commit prefixed with RUBOCOP_ACK=1 (only after the user chose this). Not commit: do nothing. In every case, report the autocorrected offenses in chat."
fi

jq -n --arg r "$reason" '{hookSpecificOutput: {
  hookEventName: "PreToolUse",
  permissionDecision: "deny",
  permissionDecisionReason: $r
}}'
