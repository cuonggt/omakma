#!/bin/bash
# Exercise Omakma's config handling. For every app that keeps config under the
# user's home, install it where the installer is safe to run, uninstall it, and
# check what survived -- all against a throwaway HOME, with every brew call
# stubbed. Nothing here installs or removes software, and nothing reaches the
# network, so it is safe to run on a machine you care about.
#
#   test/run.sh            # every case file
#   test/run.sh alacritty  # just test/app-alacritty.sh
#
# Case files are sourced, so counters accumulate across them; run.sh is the
# entry point rather than each file being runnable on its own.

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
source "$TEST_DIR/helpers.sh"

CASE_FILES=()
if [ "$#" -gt 0 ]; then
  for NAME in "$@"; do
    CASE_FILES+=("$TEST_DIR/app-$NAME.sh")
  done
else
  CASE_FILES=("$TEST_DIR"/app-*.sh)
fi

for CASE_FILE in "${CASE_FILES[@]}"; do
  if [ ! -f "$CASE_FILE" ]; then
    echo "no such case file: $CASE_FILE" >&2
    exit 1
  fi
done

test_begin

for CASE_FILE in "${CASE_FILES[@]}"; do
  echo
  echo "== $(basename "$CASE_FILE" .sh)"
  source "$CASE_FILE"
done

test_summary
