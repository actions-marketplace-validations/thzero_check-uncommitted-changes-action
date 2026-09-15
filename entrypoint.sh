#!/bin/sh
set -e

function check_uncommitted_changes() {
  if [[ -z "$(git status --porcelain $STATUS_ARGS $PATHSPEC)" ]];
  then
    echo "0"
    return 0
  else
    echo "1"
    return 1
  fi
}

function check_uncommitted_changes_status() {
  status=$(git status --porcelain $STATUS_ARGS $PATHSPEC)
  if [ -n "$status" ]; then
    echo "$status"
    exit 1
  else
    echo ""
    exit 0
  fi
}

git config --global --add safe.directory /github/workspace

# Both helpers report "there are changes" with a non-zero exit status, which set -e
# would treat as fatal. The old code hid that inside `echo ...$(...)`, where echo
# supplied the exit status; assigning the value first needs an explicit guard.
changed=$(check_uncommitted_changes) || true
changes=$(check_uncommitted_changes_status) || true

# Environment files replace the deprecated ::set-output command. `changes` may span
# lines, so it needs the heredoc form -- and unlike ::set-output, that value is taken
# literally, so the old %25/%0A/%0D escaping is dropped rather than translated.
delimiter="ghadelimiter_$(date +%s)_$$"
{
  echo "changed=$changed"
  echo "changes<<$delimiter"
  echo "$changes"
  echo "$delimiter"
} >> "$GITHUB_OUTPUT"
