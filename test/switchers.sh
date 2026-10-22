# `omakma theme`, `omakma font` and the font-size menu against a HOME where apps
# have been uninstalled.
#
# Every one of them edited config files in place and copied theme files in,
# assuming each app was still installed. Uninstall anything and switching theme
# printed a dozen errors from a routine operation, then redrew the menu as
# though nothing had happened -- and set-sublime-theme.sh went further, cloning
# a colour scheme repository into a directory tree for a Sublime Text that was
# not there.

# run_switcher <home> <sub-command> <first-choice>
# Source a real sub-command with gum answering once and then quitting, so the
# menu it re-enters at the end exits instead of waiting.
run_switcher() {
  SWITCHER_HOME="$1"
  SWITCHER_NAME="$2"
  SWITCHER_CHOICE="$3"

  TEST_OUTPUT=$(
    exec 2>&1
    # The sub-commands re-enter menu.sh, which reads a sub-command from $1 when
    # it has one. Without this it would be handed the arguments of this function.
    set --
    HOME="$SWITCHER_HOME"
    export HOME
    source "$OMAKMA_PATH/defaults/bash/functions"

    FIRST_CHOICE="$SWITCHER_CHOICE"
    GUM_CALLS_FILE="$TEST_SANDBOX/gum-calls-$SWITCHER_NAME"
    : >"$GUM_CALLS_FILE"
    gum() {
      # Counted in a file rather than a variable: theme.sh and font.sh call gum
      # inside a command substitution, so an increment would be lost with the
      # subshell and the menu would be handed the first answer all over again.
      printf 'x' >>"$GUM_CALLS_FILE"

      if [ "$(wc -c <"$GUM_CALLS_FILE" | tr -d ' ')" = 1 ]; then
        echo "$FIRST_CHOICE"
      else
        echo "Quit"
      fi
    }
    # So a clone can be seen in the output rather than actually happening.
    git() {
      echo "ATTEMPTED git $1" >&2
      return 1
    }
    code() { return 1; }

    source "$OMAKMA_PATH/bin/omakma-sub/$SWITCHER_NAME.sh"
  )
}

# assert_quiet <description>
assert_quiet() {
  case "$TEST_OUTPUT" in
  *"No such file or directory"* | *"can't read"* | *"cannot"*)
    test_fail "$1 (said: $(printf '%s' "$TEST_OUTPUT" | grep -im1 'no such file\|can.t read\|cannot'))"
    ;;
  *) test_pass "$1" ;;
  esac
}

echo "switching theme with nothing installed says nothing"
HOME_DIR=$(sandbox_home switch-theme-empty)
run_switcher "$HOME_DIR" theme Nord
assert_quiet "no errors for any app that is not there"
case "$TEST_OUTPUT" in
*"ATTEMPTED git"*) test_fail "it tried to clone a Sublime package with no Sublime installed" ;;
*) test_pass "and no Sublime package is cloned" ;;
esac
assert_gone "nor is a Sublime directory created" "$HOME_DIR/Library/Application Support/Sublime Text"

echo "switching theme still themes the apps that are installed"
HOME_DIR=$(sandbox_home switch-theme-ghostty)
mkdir -p "$HOME_DIR/.config/ghostty/themes" "$HOME_DIR/.config/zellij/themes"
cp "$OMAKMA_PATH/configs/ghostty/config" "$HOME_DIR/.config/ghostty/config"
cp "$OMAKMA_PATH/configs/zellij.kdl" "$HOME_DIR/.config/zellij/config.kdl"
run_switcher "$HOME_DIR" theme Nord
assert_quiet "no errors for the apps that are missing"
# themes/nord/ghostty holds the Ghostty theme name, which is lowercase here.
if grep -q '^theme = nord$' "$HOME_DIR/.config/ghostty/config"; then
  test_pass "ghostty's theme is set"
else
  test_fail "ghostty's theme was not set: $(grep '^theme' "$HOME_DIR/.config/ghostty/config")"
fi
if grep -q 'theme "nord"' "$HOME_DIR/.config/zellij/config.kdl"; then
  test_pass "zellij's theme is set"
else
  test_fail "zellij's theme was not set"
fi
assert_exists "and zellij gets the theme file" "$HOME_DIR/.config/zellij/themes/nord.kdl"
assert_gone "while alacritty, which is not installed, gets nothing" "$HOME_DIR/.config/alacritty"

echo "changing font size with nothing installed says nothing"
HOME_DIR=$(sandbox_home switch-size-empty)
run_switcher "$HOME_DIR" font-size 12
assert_quiet "no errors for alacritty or ghostty"

echo "changing font with nothing installed says nothing"
HOME_DIR=$(sandbox_home switch-font-empty)
run_switcher "$HOME_DIR" font "Fira Mono"
assert_quiet "no errors for any of the four files it writes"

echo "edit_config leaves a file it cannot find alone"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  edit_config "$TEST_SANDBOX/not-here.conf" "s/a/b/g"
  echo "returned=$?"
)
assert_says "returns success" "returned=0"
assert_quiet "and says nothing"

echo "edit_config applies every expression it is given"
EDIT_FILE="$TEST_SANDBOX/edit-me.conf"
printf '%s\n' "theme = Old" "font-size = 1" >"$EDIT_FILE"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  edit_config "$EDIT_FILE" "s/^theme = .*$/theme = New/g" "s/^font-size = .*$/font-size = 16/g"
)
if grep -q '^theme = New' "$EDIT_FILE" && grep -q '^font-size = 16' "$EDIT_FILE"; then
  test_pass "both lines are rewritten"
else
  test_fail "the file reads: $(tr '\n' ' ' <"$EDIT_FILE")"
fi

echo "edit_config refuses rather than reaching for BSD sed"
# BSD sed would read the expression as -i's backup suffix and mangle the file,
# so with no GNU sed under either name it must change nothing.
printf '%s\n' "theme = Old" >"$TEST_SANDBOX/bsd-only.conf"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  command() {
    if [ "$2" = gsed ]; then
      return 1
    fi
    builtin command "$@"
  }
  sed() {
    if [ "$1" = --version ]; then
      return 1
    fi
    echo "BSD sed was called" >&2
    builtin command sed "$@"
  }
  edit_config "$TEST_SANDBOX/bsd-only.conf" "s/^theme = .*$/theme = New/g"
  echo "returned=$?"
)
assert_says "it reports the missing GNU sed" "GNU sed is not installed"
assert_says "without stopping the switcher" "returned=0"
case "$TEST_OUTPUT" in
*"BSD sed was called"*) test_fail "it fell back to BSD sed, which would mangle the file" ;;
*) test_pass "and does not fall back to BSD sed" ;;
esac
if grep -q '^theme = Old$' "$TEST_SANDBOX/bsd-only.conf"; then
  test_pass "the file is untouched"
else
  test_fail "the file was changed: $(cat "$TEST_SANDBOX/bsd-only.conf")"
fi

echo "update_config will not create a config directory for a missing app"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  update_config "$OMAKMA_PATH/configs/zellij.kdl" "$TEST_SANDBOX/no-such-app/config.kdl"
  echo "returned=$?"
)
assert_says "returns success" "returned=0"
assert_gone "and creates nothing" "$TEST_SANDBOX/no-such-app"

echo "update_config writes into a config directory that is there"
mkdir -p "$TEST_SANDBOX/real-app"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  update_config "$OMAKMA_PATH/configs/zellij.kdl" "$TEST_SANDBOX/real-app/config.kdl"
)
assert_same "the file is placed" "$TEST_SANDBOX/real-app/config.kdl" "$OMAKMA_PATH/configs/zellij.kdl"
