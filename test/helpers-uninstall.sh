# What the uninstall helpers report, and what the menu therefore shows.
#
# Both helpers used to end in `|| true` with stderr discarded, so every
# uninstaller returned 0 whatever happened and bin/omakma-sub/uninstall.sh
# always reached its "Uninstall completed!" spinner. These cases pin down the
# three outcomes it now has to tell apart: already gone, removed, and refused.

echo "a package that is not installed is nothing to do, not a failure"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  # brew list fails: nothing of that name is installed.
  brew() {
    if [ "$1" = list ]; then
      return 1
    fi
    echo "uninstall should not have been attempted"
  }
  app_uninstall somecask
  brew_app_uninstall someformula
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_UNINSTALLS[@]}"
  report_failed_uninstalls
)
assert_says "returns success" "returned=0"
assert_says "nothing is recorded" "recorded=0"
case "$TEST_OUTPUT" in
*"should not have been attempted"*) test_fail "it tried to uninstall something absent" ;;
*) test_pass "no uninstall is attempted" ;;
esac
case "$TEST_OUTPUT" in
*"could not remove"*) test_fail "an absent package was reported as a failure" ;;
*) test_pass "re-running stays silent" ;;
esac

echo "a package that removes cleanly is not reported"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() { return 0; }
  app_uninstall somecask
  echo "recorded=${#OMAKMA_FAILED_UNINSTALLS[@]}"
  report_failed_uninstalls
)
assert_says "nothing is recorded" "recorded=0"
case "$TEST_OUTPUT" in
*"could not remove"*) test_fail "a clean removal was reported as a failure" ;;
*) test_pass "the summary stays silent" ;;
esac

echo "a removal Homebrew refuses is recorded, with its reason left visible"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  # Installed, but the removal fails -- the app is still running.
  brew() {
    if [ "$1" = list ]; then
      return 0
    fi
    echo "Error: the application is still running" >&2
    return 1
  }
  app_uninstall ghostty
  brew_app_uninstall zellij
  echo "recorded=${#OMAKMA_FAILED_UNINSTALLS[@]}"
  report_failed_uninstalls
)
assert_says "both are recorded" "recorded=2"
assert_says "it says so at the point of failure" "Could not remove ghostty with Homebrew."
assert_says "Homebrew's reason is no longer discarded" "Error: the application is still running"
assert_says "the cask is named in the summary" "  - ghostty"
assert_says "the formula is named in the summary" "  - zellij"
assert_says "and the summary says what was still done" "config the uninstaller cleans up was still removed"

echo "a real uninstaller carries on past a refused removal"
HOME_DIR=$(sandbox_home zellij-refused)
mkdir -p "$HOME_DIR/.config/zellij/themes"
cp "$OMAKMA_PATH/configs/zellij.kdl" "$HOME_DIR/.config/zellij/config.kdl"
cp "$OMAKMA_PATH/themes/default/zellij.kdl" "$HOME_DIR/.config/zellij/themes/default.kdl"
TEST_OUTPUT=$(
  exec 2>&1
  HOME="$HOME_DIR"
  export HOME
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() {
    if [ "$1" = list ]; then
      return 0
    fi
    return 1
  }
  source "$OMAKMA_PATH/uninstall/terminal/app-zellij.sh"
  echo "recorded=${#OMAKMA_FAILED_UNINSTALLS[@]}"
)
assert_says "the refused removal is recorded" "recorded=1"
assert_gone "and the config cleanup still ran" "$HOME_DIR/.config/zellij"

echo "the summary is silent, and safe, when nothing failed"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  report_failed_uninstalls
  echo "returned=$?"
)
assert_says "returns success on an empty list" "returned=0"
case "$TEST_OUTPUT" in
*"could not remove"*) test_fail "the summary printed with nothing to report" ;;
*unbound*) test_fail "empty array expansion broke under set -u" ;;
*) test_pass "prints nothing, and does not trip set -u" ;;
esac
