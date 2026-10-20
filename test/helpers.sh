# Shared helpers for Omakma's config-handling tests.
#
# These tests source the real installers and uninstallers, so everything they
# touch has to be fake. Each case gets its own throwaway HOME inside a sandbox
# under $TMPDIR, and every brew call is stubbed: nothing here installs or
# removes software, and nothing reaches the network.
#
# Sourced by test/run.sh, which is the entry point.

OMAKMA_PATH=${OMAKMA_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
export OMAKMA_PATH

TEST_PASS=0
TEST_FAIL=0
TEST_SANDBOX=""
TEST_OUTPUT=""

test_begin() {
  TEST_SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/omakma-test.XXXXXX") || exit 1
  trap test_cleanup EXIT
}

test_cleanup() {
  case "$TEST_SANDBOX" in
  */omakma-test.*) rm -rf "$TEST_SANDBOX" ;;
  esac
}

# sandbox_home <name>
# A throwaway HOME for one case. These tests delete config directories, so a
# path that escaped the sandbox would take the user's own files with it: anything
# outside it is refused rather than used.
sandbox_home() {
  local home="$TEST_SANDBOX/$1"

  case "$home" in
  "$TEST_SANDBOX"/?*) ;;
  *)
    echo "refusing $home as a fake HOME: outside the sandbox" >&2
    exit 1
    ;;
  esac

  mkdir -p "$home"
  printf '%s' "$home"
}

# run_script <home> <install|uninstall> <path>
# Source one installer or uninstaller the way bin/omakma does -- shared helpers
# loaded, every brew call stubbed -- against a sandbox HOME. What it printed is
# left in $TEST_OUTPUT for assert_says.
#
# The brew stubs below are called only by the script being sourced, which
# ShellCheck cannot see; SC2329 is disabled for this function alone rather than
# repo-wide, since nothing else stubs anything.
# shellcheck disable=SC2329
run_script() {
  local home="$1"
  local tree="$2"
  local script="$3"

  case "$home" in
  "$TEST_SANDBOX"/?*) ;;
  *)
    echo "refusing to run $tree/$script against $home" >&2
    exit 1
    ;;
  esac

  TEST_OUTPUT=$(
    HOME="$home"
    export HOME
    source "$OMAKMA_PATH/defaults/bash/functions"
    brew_app_install() { :; }
    app_install() { :; }
    brew_app_uninstall() { :; }
    app_uninstall() { :; }
    source "$OMAKMA_PATH/$tree/$script"
  ) 2>&1
}

# rewrite_line <file> <prefix> <replacement>
# Replace the line starting with <prefix>, the way `omakma theme` and the font
# menus edit these files in place. Done in bash rather than with `sed -i`, whose
# spelling differs between BSD and GNU.
rewrite_line() {
  local file="$1"
  local prefix="$2"
  local replacement="$3"
  local tmp="$file.rewritten"
  local line

  : >"$tmp"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
    "$prefix"*) printf '%s\n' "$replacement" >>"$tmp" ;;
    *) printf '%s\n' "$line" >>"$tmp" ;;
    esac
  done <"$file"

  mv "$tmp" "$file"
}

test_pass() {
  TEST_PASS=$((TEST_PASS + 1))
  echo "  ok   $1"
}

test_fail() {
  TEST_FAIL=$((TEST_FAIL + 1))
  echo "  FAIL $1"
}

assert_gone() {
  if [ -e "$2" ]; then test_fail "$1 (still present: $2)"; else test_pass "$1"; fi
}

assert_exists() {
  if [ -e "$2" ]; then test_pass "$1"; else test_fail "$1 (missing: $2)"; fi
}

assert_same() {
  if cmp -s "$2" "$3"; then test_pass "$1"; else test_fail "$1 ($2 differs from $3)"; fi
}

# assert_says <description> <substring>
# The scripts report what they kept and restored; that reporting is behaviour
# worth holding on to, not decoration.
assert_says() {
  case "$TEST_OUTPUT" in
  *"$2"*) test_pass "$1" ;;
  *) test_fail "$1 (not in output: $2)" ;;
  esac
}

test_summary() {
  echo
  echo "pass=$TEST_PASS fail=$TEST_FAIL"
  [ "$TEST_FAIL" -eq 0 ]
}
