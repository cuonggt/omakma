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
assert_says "and the summary says nothing was half-removed" "Their config was left in place"

echo "a real uninstaller stops at a refused removal rather than half-removing"
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
  # `return` ends the sourced script, not this subshell, so what it returned is
  # the evidence that it stopped -- anything echoed after the source would run
  # either way.
  source "$OMAKMA_PATH/uninstall/terminal/app-zellij.sh"
  echo "source_returned=$?"
)
assert_says "it says it is leaving the rest alone" "Leaving the rest of it alone"
assert_says "the uninstaller stops, reporting failure" "source_returned=1"
assert_exists "the config of a still-installed zellij is left alone" "$HOME_DIR/.config/zellij/config.kdl"
assert_exists "including the theme file" "$HOME_DIR/.config/zellij/themes/default.kdl"

echo "but a removal that works still cleans the config up"
HOME_DIR=$(sandbox_home zellij-removed)
mkdir -p "$HOME_DIR/.config/zellij/themes"
cp "$OMAKMA_PATH/configs/zellij.kdl" "$HOME_DIR/.config/zellij/config.kdl"
cp "$OMAKMA_PATH/themes/default/zellij.kdl" "$HOME_DIR/.config/zellij/themes/default.kdl"
TEST_OUTPUT=$(
  exec 2>&1
  HOME="$HOME_DIR"
  export HOME
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() { return 0; }
  source "$OMAKMA_PATH/uninstall/terminal/app-zellij.sh"
)
assert_gone "the config goes when the app actually went" "$HOME_DIR/.config/zellij"

echo "uninstall_failed reports failure, which is what makes them stop"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  uninstall_failed something
  echo "returned=$?"
)
assert_says "it returns non-zero" "returned=1"

echo "every uninstaller with more to do after the removal stops on a refusal"
while IFS= read -r UNINSTALL_FILE; do
  UNINSTALL_BODY=$(grep -cv '^[[:space:]]*#\|^[[:space:]]*$' "$OMAKMA_PATH/$UNINSTALL_FILE")

  if [ "$UNINSTALL_BODY" -le 1 ]; then
    continue
  fi

  case "$(cat "$OMAKMA_PATH/$UNINSTALL_FILE")" in
  *"|| return 1 2>/dev/null || exit 1"*) ;;
  *) test_fail "$UNINSTALL_FILE would carry on past a refused removal" ;;
  esac
done <<<"$(cd "$OMAKMA_PATH" && find uninstall -name '*.sh' | sort)"
test_pass "none of them would carry on past a refused removal"

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
