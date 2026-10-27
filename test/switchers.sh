# `omakma theme`, `omakma font` and the font-size menu against a HOME where apps
# have been uninstalled.
#
# Every one of them edited config files in place and copied theme files in,
# assuming each app was still installed. Uninstall anything and switching theme
# printed a dozen errors from a routine operation, then redrew the menu as
# though nothing had happened -- and set-sublime-theme.sh went further, cloning
# a colour scheme repository into a directory tree for a Sublime Text that was
# not there.

# run_switcher <home> <sub-command> <first-choice> [tools: fail|ok]
# Source a real sub-command with gum answering once and then quitting, so the
# menu it re-enters at the end exits instead of waiting. "tools" decides whether
# the Sublime package clone and the VS Code extension install succeed; it
# defaults to fail, which is what every case before this one assumed.
run_switcher() {
  SWITCHER_HOME="$1"
  SWITCHER_NAME="$2"
  SWITCHER_CHOICE="$3"
  SWITCHER_TOOLS="${4:-fail}"

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
    TOOLS_MODE="$SWITCHER_TOOLS"

    # So a clone can be seen in the output rather than actually happening. When
    # it is meant to work, the package directory is created, since that is what
    # the colour scheme the config names lives in.
    git() {
      echo "ATTEMPTED git $1" >&2

      if [ "$TOOLS_MODE" = ok ] && [ "$1" = clone ]; then
        mkdir -p "$3"
        return 0
      fi

      return 1
    }
    code() {
      if [ "$TOOLS_MODE" = ok ]; then
        return 0
      fi

      return 1
    }

    # Nothing here may reach the network or the real font store. GitHub's
    # runners have wget, so leaving font.sh unstubbed meant it downloaded a font
    # archive for real and then failed copying it into a sandbox HOME with no
    # Library/Fonts -- a failure that could not happen on a machine without
    # wget, which is why it passed locally and in a container.
    fc-list() {
      printf '%s\n' "JetBrainsMono Nerd Font" "CaskaydiaMono Nerd Font" \
        "FiraMono Nerd Font" "MesloLGS Nerd Font"
    }
    fc-cache() { :; }
    clear() { :; }
    wget() {
      echo "ATTEMPTED wget" >&2
      return 1
    }
    curl() {
      echo "ATTEMPTED curl" >&2
      return 1
    }
    unzip() {
      echo "ATTEMPTED unzip" >&2
      return 1
    }

    source "$OMAKMA_PATH/bin/omakma-sub/$SWITCHER_NAME.sh"
  )
}

# assert_no_errors <description>
# No error from any app that is not installed. Named apart from helpers.sh's
# assert_quiet, which takes a substring that must be absent: this file is
# sourced before test/update.sh, so defining a one-argument assert_quiet here
# silently took over its calls and left five of them checking for "cannot"
# instead of the message they named. They passed, which is worse.
assert_no_errors() {
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
assert_no_errors "no errors for any app that is not there"
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
assert_no_errors "no errors for the apps that are missing"
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
assert_no_errors "no errors for alacritty or ghostty"

echo "changing font with nothing installed says nothing"
HOME_DIR=$(sandbox_home switch-font-empty)
run_switcher "$HOME_DIR" font "Fira Mono"
assert_no_errors "no errors for any of the four files it writes"
case "$TEST_OUTPUT" in
*"ATTEMPTED wget"* | *"ATTEMPTED curl"*)
  test_fail "the switcher tried to download a font, so this suite needs the network"
  ;;
*) test_pass "and no font is downloaded" ;;
esac
assert_gone "nor is a font store created" "$HOME_DIR/Library/Fonts"

echo "a font that is not installed yet is still only a download away"
HOME_DIR=$(sandbox_home switch-font-missing)
mkdir -p "$HOME_DIR/.config/alacritty"
cp "$OMAKMA_PATH/configs/alacritty/fonts/JetBrainsMono.toml" "$HOME_DIR/.config/alacritty/font.toml"
# fc-list reports nothing, so set_font takes the download path -- with wget
# blocked, it should report that and carry on rather than failing on the copy.
TEST_OUTPUT=$(
  exec 2>&1
  set --
  HOME="$HOME_DIR"
  export HOME
  source "$OMAKMA_PATH/defaults/bash/functions"
  GUM_CALLS_FILE="$TEST_SANDBOX/gum-calls-font-missing"
  : >"$GUM_CALLS_FILE"
  gum() {
    printf 'x' >>"$GUM_CALLS_FILE"
    if [ "$(wc -c <"$GUM_CALLS_FILE" | tr -d ' ')" = 1 ]; then
      echo "Fira Mono"
    else
      echo "Quit"
    fi
  }
  fc-list() { :; }
  wget() { return 1; }
  code() { return 1; }
  source "$OMAKMA_PATH/bin/omakma-sub/font.sh"
)
assert_says "it says the download failed" "Failed to download"
assert_no_errors "and nothing else went wrong"
assert_same "the alacritty font config is still switched" "$HOME_DIR/.config/alacritty/font.toml" "$OMAKMA_PATH/configs/alacritty/fonts/FiraMono.toml"

echo "edit_config leaves a file it cannot find alone"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  edit_config "$TEST_SANDBOX/not-here.conf" "s/a/b/g"
  echo "returned=$?"
)
assert_says "returns success" "returned=0"
assert_no_errors "and says nothing"

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

# sandbox_sublime <name>
# A HOME with Sublime Text's config in place, so the theme setter gets past its
# "is Sublime even installed" guard and reaches the clone.
sandbox_sublime() {
  local home
  home=$(sandbox_home "$1")

  mkdir -p "$home/Library/Application Support/Sublime Text/Packages/User"
  cp "$OMAKMA_PATH/configs/sublime/Preferences.sublime-settings" \
    "$home/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"

  printf '%s' "$home"
}

# sandbox_vscode <name>
# A HOME with VS Code's settings.json in place.
sandbox_vscode() {
  local home
  home=$(sandbox_home "$1")

  mkdir -p "$home/Library/Application Support/Code/User"
  cp "$OMAKMA_PATH/configs/vscode.json" \
    "$home/Library/Application Support/Code/User/settings.json"

  printf '%s' "$home"
}

echo "a Sublime colour scheme that will not download leaves the theme alone"
HOME_DIR=$(sandbox_sublime switch-theme-sublime-fail)
SUBLIME_PREFS="$HOME_DIR/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"
cp "$SUBLIME_PREFS" "$TEST_SANDBOX/sublime-prefs.before"
run_switcher "$HOME_DIR" theme Nord fail
assert_says "the download is reported" "Could not download"
assert_says "and what it meant for the theme" "Sublime Text's theme was left as it was"
assert_same "the preferences are untouched" "$SUBLIME_PREFS" "$TEST_SANDBOX/sublime-prefs.before"

echo "a Sublime colour scheme that downloads is applied"
HOME_DIR=$(sandbox_sublime switch-theme-sublime-ok)
SUBLIME_PREFS="$HOME_DIR/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"
cp "$SUBLIME_PREFS" "$TEST_SANDBOX/sublime-prefs-ok.before"
run_switcher "$HOME_DIR" theme Nord ok
assert_quiet "nothing is reported as a failure" "was left as it was"
if cmp -s "$SUBLIME_PREFS" "$TEST_SANDBOX/sublime-prefs-ok.before"; then
  test_fail "the preferences were not rewritten, so the case above proves nothing"
else
  test_pass "the preferences are rewritten"
fi

echo "a VS Code extension that will not install leaves the theme alone"
HOME_DIR=$(sandbox_vscode switch-theme-vscode-fail)
VSCODE_SETTINGS="$HOME_DIR/Library/Application Support/Code/User/settings.json"
cp "$VSCODE_SETTINGS" "$TEST_SANDBOX/vscode-settings.before"
run_switcher "$HOME_DIR" theme Nord fail
assert_says "the extension is reported" "Could not finish setting up"
assert_says "and what it meant for the theme" "VS Code's theme was left as it was"
assert_same "the settings are untouched" "$VSCODE_SETTINGS" "$TEST_SANDBOX/vscode-settings.before"

echo "a VS Code extension that installs is applied"
HOME_DIR=$(sandbox_vscode switch-theme-vscode-ok)
VSCODE_SETTINGS="$HOME_DIR/Library/Application Support/Code/User/settings.json"
cp "$VSCODE_SETTINGS" "$TEST_SANDBOX/vscode-settings-ok.before"
run_switcher "$HOME_DIR" theme Nord ok
assert_quiet "nothing is reported as a failure" "was left as it was"
if cmp -s "$VSCODE_SETTINGS" "$TEST_SANDBOX/vscode-settings-ok.before"; then
  test_fail "the settings were not rewritten, so the case above proves nothing"
else
  test_pass "the settings are rewritten"
fi
