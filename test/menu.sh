# What the install and uninstall menus tell you.
#
# Both gated their "completed!" spinner on the sourced script's exit status, and
# both then cleared the screen. Since the install helpers return 0 when a
# package is skipped and the uninstall helpers did the same, the spinner always
# fired and the clear wiped the only account of what had actually happened.
#
# The uninstall side was fixed when the helpers stopped swallowing failures, but
# neither dispatch had ever been driven by a test.

# run_menu <home> <install|uninstall> <choice> <gum-file> <brew: ok|fail|refuse>
run_menu() {
  MENU_HOME="$1"
  MENU_NAME="$2"
  MENU_CHOICE="$3"
  MENU_FILE="$4"
  MENU_BREW="$5"

  TEST_OUTPUT=$(
    exec 2>&1
    set --
    HOME="$MENU_HOME"
    export HOME
    source "$OMAKMA_PATH/defaults/bash/functions"

    FIRST_CHOICE="$MENU_CHOICE"
    GUM_FILE="$MENU_FILE"
    # Counted in a file: the menus read gum inside a command substitution, so a
    # variable would be incremented in a subshell and lost.
    COUNT_FILE="$TEST_SANDBOX/menu-gum-$MENU_NAME-$MENU_BREW"
    : >"$COUNT_FILE"

    gum() {
      # Reported rather than counted, so the spinner does not use up an answer.
      if [ "$1" = spin ]; then
        echo "SPIN: $*"
        return 0
      fi

      if [ "$1" = confirm ]; then
        return 0
      fi

      if [ "$1" = file ]; then
        echo "$GUM_FILE"
        return 0
      fi

      printf 'x' >>"$COUNT_FILE"

      if [ "$(wc -c <"$COUNT_FILE" | tr -d ' ')" = 1 ]; then
        echo "$FIRST_CHOICE"
      else
        echo "Quit"
      fi
    }
    clear() { echo "CLEARED"; }

    if [ "$MENU_BREW" = ok ]; then
      brew() { return 0; }
    elif [ "$MENU_BREW" = refuse ]; then
      # Installed, but the removal is refused.
      brew() {
        if [ "$1" = list ]; then
          return 0
        fi
        return 1
      }
    else
      brew() { return 1; }
    fi

    app_installed() { return 1; }

    source "$OMAKMA_PATH/bin/omakma-sub/$MENU_NAME.sh"
  )
}

echo "installing something Homebrew will not hand over says so"
HOME_DIR=$(sandbox_home menu-install-fails)
run_menu "$HOME_DIR" install Dropbox "" fail
assert_says "it reports the package at the point of failure" "Could not install dropbox from Homebrew"
assert_says "and names it in the summary" "  - dropbox"
case "$TEST_OUTPUT" in
*"Install completed!"*) test_fail "it still claimed the install completed" ;;
*) test_pass "it does not claim the install completed" ;;
esac
case "$TEST_OUTPUT" in
*CLEARED*) test_fail "it cleared the screen, wiping the only account of the failure" ;;
*) test_pass "and does not clear the screen" ;;
esac

echo "installing something that works still says it completed"
HOME_DIR=$(sandbox_home menu-install-works)
run_menu "$HOME_DIR" install Dropbox "" ok
assert_says "the spinner runs" "Install completed!"
assert_says "the screen is cleared as before" "CLEARED"
case "$TEST_OUTPUT" in
*"could not be installed"*) test_fail "it reported a failure that did not happen" ;;
*) test_pass "and no failure is reported" ;;
esac

echo "backing out of the menu claims nothing"
HOME_DIR=$(sandbox_home menu-install-back)
run_menu "$HOME_DIR" install "<< Back" "" fail
case "$TEST_OUTPUT" in
*"Install completed!"*) test_fail "it claimed an install that never ran" ;;
*) test_pass "no spinner" ;;
esac
assert_says "the screen is cleared as before" "CLEARED"

echo "a removal Homebrew refuses is reported by the uninstall menu"
HOME_DIR=$(sandbox_home menu-uninstall-refused)
mkdir -p "$HOME_DIR/.config/zellij"
cp "$OMAKMA_PATH/configs/zellij.kdl" "$HOME_DIR/.config/zellij/config.kdl"
run_menu "$HOME_DIR" uninstall "" "$OMAKMA_PATH/uninstall/terminal/app-zellij.sh" refuse
assert_says "it reports the refusal" "Could not remove zellij with Homebrew"
assert_says "and names it in the summary" "  - zellij"
assert_says "saying the config was left alone" "Their config was left in place"
case "$TEST_OUTPUT" in
*"Uninstall completed!"*) test_fail "it still claimed the uninstall completed" ;;
*) test_pass "it does not claim the uninstall completed" ;;
esac
case "$TEST_OUTPUT" in
*CLEARED*) test_fail "it cleared the screen over the failure" ;;
*) test_pass "and does not clear the screen" ;;
esac
assert_exists "the config of the still-installed zellij survives" "$HOME_DIR/.config/zellij/config.kdl"

echo "a removal that works still says it completed"
HOME_DIR=$(sandbox_home menu-uninstall-works)
mkdir -p "$HOME_DIR/.config/zellij"
cp "$OMAKMA_PATH/configs/zellij.kdl" "$HOME_DIR/.config/zellij/config.kdl"
run_menu "$HOME_DIR" uninstall "" "$OMAKMA_PATH/uninstall/terminal/app-zellij.sh" ok
assert_says "the spinner runs" "Uninstall completed!"
assert_says "the screen is cleared as before" "CLEARED"
assert_gone "and the config is cleaned up" "$HOME_DIR/.config/zellij"

echo "every entry in the install menu resolves to an installer that is there"
# Driven through the real dispatch rather than re-deriving the paths here. Three
# entries are routed into install/terminal/ by name -- dev-language, dev-database
# and ollama, none of which is a desktop app -- and everything else falls through
# to install/desktop/optional/, so a label whose file is missing shows up only as
# bash failing to source it. There used to be two ollama installers, one in each
# tree, and the desktop one was reachable only through the file browser; deleting
# it is safe exactly as long as the name still routes somewhere that exists.
#
# The labels are read out of the sub-command so this list cannot drift from the
# menu it is checking, and the loop is fed by a heredoc rather than a pipe, which
# would put the counters in a subshell and lose them.
MENU_LABELS=$(sed -n '/^CHOICES=(/,/^)/p' "$OMAKMA_PATH/bin/omakma-sub/install.sh" | sed -n 's/^  "\(.*\)"$/\1/p')
assert_parsed "the labels are read out of the install sub-command" "$MENU_LABELS"
while IFS= read -r MENU_LABEL; do
  MENU_ENTRY=$(printf '%s' "$MENU_LABEL" | awk -F ' {2,}' '{print $1}')

  # Neither opens an installer by name: one opens the file browser, one leaves.
  if [ "$MENU_ENTRY" = "> All" ] || [ "$MENU_ENTRY" = "<< Back" ]; then
    continue
  fi

  MENU_SLUG=$(printf '%s' "$MENU_ENTRY" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  HOME_DIR=$(sandbox_home "menu-resolve-$MENU_SLUG")
  run_menu "$HOME_DIR" install "$MENU_ENTRY" "" ok
  assert_quiet "$MENU_ENTRY resolves to an installer" "No such file or directory"
done <<MENU_ENTRIES
$MENU_LABELS
MENU_ENTRIES
