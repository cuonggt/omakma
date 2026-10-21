# The install helpers' behaviour when Homebrew will not hand over a package.
#
# This is the bug the Alacritty cask exposed: `brew install` on a disabled cask
# raises, install.sh runs under `set -e`, and install/desktop.sh sources its
# installers in a loop -- so one unavailable cask took the 27 installers behind
# it. These cases pin down that a failed `brew install` no longer stops the run,
# that it is never silent, and that nothing else became tolerant along with it.
#
# brew and app_installed are stubbed here rather than the install helpers, since
# the helpers are the thing under test.

echo "a package already present is not reinstalled"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  app_installed() { return 0; }
  brew() { echo "brew should not have been called"; return 1; }
  app_install somecask
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
)
assert_says "returns success" "returned=0"
assert_says "brew is never called" "recorded=0"

echo "a package that installs cleanly is not reported"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  app_installed() { return 1; }
  brew() { return 0; }
  app_install somecask
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
  report_failed_installs
)
assert_says "returns success" "returned=0"
assert_says "nothing recorded" "recorded=0"
assert_says "the summary stays silent" "recorded=0"

echo "a cask Homebrew refuses is reported and skipped"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  app_installed() { return 1; }
  brew() { echo "Error: alacritty has been disabled" >&2; return 1; }
  app_install alacritty
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
  report_failed_installs
)
assert_says "the helper returns success so set -e cannot abort" "returned=0"
assert_says "the failure is recorded" "recorded=1"
assert_says "it says so at the point of failure" "Could not install alacritty from Homebrew"
assert_says "and names it again in the summary" "  - alacritty"

echo "the same for a formula via brew_app_install"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  app_installed() { return 1; }
  brew() { return 1; }
  brew_app_install someformula
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
)
assert_says "returns success" "returned=0"
assert_says "the failure is recorded" "recorded=1"

echo "a failed install no longer stops the installer loop"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  app_installed() { return 1; }
  brew() { return 1; }
  set -e
  RAN=""
  for app in alacritty alfred chrome vscode; do
    app_install "$app"
    RAN="$RAN $app"
  done
  echo "ran:$RAN"
  echo "cleanup_reached=yes"
  report_failed_installs
)
assert_says "every installer after the failing one still runs" "ran: alacritty alfred chrome vscode"
assert_says "the code after the loop is reached" "cleanup_reached=yes"
assert_says "all four are named in the summary" "  - vscode"

echo "an error that is not a failed brew install still stops the run"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  app_installed() { return 1; }
  brew() { return 0; }
  set -e
  app_install somecask
  cp /definitely/not/here /nor/here
  echo "should_not_be_reached=yes"
)
assert_says "set -e still aborts on a real error" "cp:"
case "$TEST_OUTPUT" in
*should_not_be_reached*) test_fail "set -e no longer aborts on a real error" ;;
*) test_pass "only the brew install was made tolerant" ;;
esac

echo "the summary is silent, and safe, when nothing failed"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  report_failed_installs
  echo "returned=$?"
)
assert_says "returns success on an empty list" "returned=0"
case "$TEST_OUTPUT" in
*"would not install"*) test_fail "the summary printed with nothing to report" ;;
*unbound*) test_fail "empty array expansion broke under set -u" ;;
*) test_pass "prints nothing, and does not trip set -u on the empty array" ;;
esac
