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

echo "brew_install skips a formula that is already there"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  # if rather than case: bash 3.2 mis-parses a case pattern's closing paren
  # inside $( ).
  brew() {
    if [ "$1" = list ]; then
      return 0
    fi
    echo "installed anyway"
  }
  brew_install somefomula
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
)
assert_says "returns success" "returned=0"
assert_says "nothing recorded" "recorded=0"
case "$TEST_OUTPUT" in
*"installed anyway"*) test_fail "brew install ran for a formula already present" ;;
*) test_pass "brew install is not run" ;;
esac

echo "brew_install and cask_install record what Homebrew refuses"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() { return 1; }
  brew_install someformula
  cask_install somecask
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
  report_failed_installs
)
assert_says "returns success" "returned=0"
assert_says "both are recorded" "recorded=2"
assert_says "the formula is named" "  - someformula"
assert_says "the cask is named" "  - somecask"

echo "the real apps-terminal.sh survives Homebrew refusing everything"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() { return 1; }
  set -e
  source "$OMAKMA_PATH/install/terminal/apps-terminal.sh"
  echo "reached_end=yes"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
)
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "all thirteen are recorded" "recorded=13"

echo "gum is deliberately still fatal"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() { return 1; }
  set -e
  source "$OMAKMA_PATH/install/terminal/required/app-gum.sh"
  echo "reached_end=yes"
)
case "$TEST_OUTPUT" in
*reached_end*) test_fail "a failed gum install no longer stops the run" ;;
*) test_pass "a failed gum install still stops the run" ;;
esac

echo "languages that need mise are skipped when mise is missing"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  # Emptying PATH is the point: it is how `command -v mise` and `command -v php`
  # inside the real installer are made to find nothing. SC2123 reads any PATH
  # assignment as a slip, and is disabled here rather than repo-wide, where it
  # is worth keeping.
  # shellcheck disable=SC2123
  PATH="$TEST_SANDBOX/empty-path"
  mkdir -p "$PATH"
  OMAKMA_FIRST_RUN_LANGUAGES="Node.js"
  set -e
  source "$OMAKMA_PATH/install/terminal/select-dev-language.sh"
  echo "reached_end=yes"
)
assert_says "it says which language it skipped" "Skipping Node.js: mise is not available."
assert_says "and does not take the install down" "reached_end=yes"

echo "composer and valet are skipped when PHP could not be installed"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  # Emptying PATH is the point: it is how `command -v mise` and `command -v php`
  # inside the real installer are made to find nothing. SC2123 reads any PATH
  # assignment as a slip, and is disabled here rather than repo-wide, where it
  # is worth keeping.
  # shellcheck disable=SC2123
  PATH="$TEST_SANDBOX/empty-path"
  mkdir -p "$PATH"
  brew() { return 1; }
  OMAKMA_FIRST_RUN_LANGUAGES="PHP"
  set -e
  source "$OMAKMA_PATH/install/terminal/select-dev-language.sh"
  echo "reached_end=yes"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
)
assert_says "the failed PHP install is recorded" "Could not install php from Homebrew"
assert_says "nothing downstream of PHP is attempted" "reached_end=yes"
assert_says "exactly one failure" "recorded=1"

echo "a tap-based installer survives the tap failing"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  app_installed() { return 1; }
  # Fails at `brew tap`, before the install is ever reached.
  brew() {
    if [ "$1" = tap ]; then
      return 1
    fi
    echo "install should not have been reached"
  }
  set -e
  source "$OMAKMA_PATH/install/desktop/app-localsend.sh"
  echo "reached_end=yes"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
)
assert_says "a failed tap does not stop the run" "reached_end=yes"
assert_says "it is recorded once" "recorded=1"
assert_says "and named" "Could not install localsend from Homebrew"
case "$TEST_OUTPUT" in
*"should not have been reached"*) test_fail "it tried to install from a tap that failed" ;;
*) test_pass "the install is not attempted after the tap failed" ;;
esac

echo "a tap-based installer survives the install failing"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  app_installed() { return 1; }
  # The tap succeeds; the install is what Homebrew refuses.
  brew() {
    if [ "$1" = tap ]; then
      return 0
    fi
    return 1
  }
  set -e
  source "$OMAKMA_PATH/install/desktop/app-localsend.sh"
  source "$OMAKMA_PATH/install/desktop/app-phpmon.sh"
  echo "reached_end=yes"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
  report_failed_installs
)
assert_says "neither stops the run" "reached_end=yes"
assert_says "both are recorded" "recorded=2"
assert_says "localsend is named in the summary" "  - localsend"
assert_says "phpmon is named in the summary" "  - phpmon"

echo "a tap-based installer does nothing when the app is already there"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  app_installed() { return 0; }
  brew() { echo "brew should not have been called"; }
  set -e
  source "$OMAKMA_PATH/install/desktop/app-localsend.sh"
  source "$OMAKMA_PATH/install/desktop/app-phpmon.sh"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
)
assert_says "nothing recorded" "recorded=0"
case "$TEST_OUTPUT" in
*"should not have been called"*) test_fail "brew ran for an app already present" ;;
*) test_pass "neither taps nor installs" ;;
esac
