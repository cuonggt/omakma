#!/bin/bash
# Exercise Omakma's config handling. For every app that keeps config under the
# user's home, install it where the installer is safe to run, uninstall it, and
# check what survived -- all against a throwaway HOME, with every brew call
# stubbed. Nothing here installs or removes software, and nothing reaches the
# network, so it is safe to run on a machine you care about.
#
#   test/run.sh            # every case file
#   test/run.sh alacritty  # just test/app-alacritty.sh
#   test/run.sh install    # just test/helpers-install.sh
#
# Case files are sourced, so counters accumulate across them; run.sh is the
# entry point rather than each file being runnable on its own.

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
source "$TEST_DIR/helpers.sh"

CASE_FILES=()
if [ "$#" -gt 0 ]; then
  for NAME in "$@"; do
    if [ -f "$TEST_DIR/app-$NAME.sh" ]; then
      CASE_FILES+=("$TEST_DIR/app-$NAME.sh")
    elif [ -f "$TEST_DIR/helpers-$NAME.sh" ]; then
      CASE_FILES+=("$TEST_DIR/helpers-$NAME.sh")
    else
      echo "no case file for: $NAME" >&2
      exit 1
    fi
  done
else
  # An unmatched glob stays literal in bash 3.2, so each candidate is tested
  # rather than assumed to exist.
  for CANDIDATE in "$TEST_DIR"/app-*.sh "$TEST_DIR"/helpers-*.sh; do
    if [ -f "$CANDIDATE" ]; then
      CASE_FILES+=("$CANDIDATE")
    fi
  done
fi

test_begin

for CASE_FILE in "${CASE_FILES[@]}"; do
  echo
  echo "== $(basename "$CASE_FILE" .sh)"
  source "$CASE_FILE"
done

test_summary
