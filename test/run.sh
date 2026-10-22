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
    FOUND=""
    for CANDIDATE in "$TEST_DIR/app-$NAME.sh" "$TEST_DIR/helpers-$NAME.sh" "$TEST_DIR/$NAME.sh"; do
      if [ -f "$CANDIDATE" ]; then
        FOUND="$CANDIDATE"
        break
      fi
    done

    if [ -z "$FOUND" ]; then
      echo "no case file for: $NAME" >&2
      exit 1
    fi

    CASE_FILES+=("$FOUND")
  done
else
  # Everything in here except this script and the two it shares the directory
  # with, rather than a list of name prefixes a new case file could fail to
  # match and so never run.
  for CANDIDATE in "$TEST_DIR"/*.sh; do
    case "$(basename "$CANDIDATE")" in
    run.sh | lint.sh | helpers.sh) ;;
    *) CASE_FILES+=("$CANDIDATE") ;;
    esac
  done
fi

test_begin

for CASE_FILE in "${CASE_FILES[@]}"; do
  echo
  echo "== $(basename "$CASE_FILE" .sh)"
  source "$CASE_FILE"
done

test_summary
