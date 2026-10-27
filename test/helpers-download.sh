# What a failed download does to an install.
#
# Every network operation under install/ ran unguarded, and install.sh runs
# under `set -e`. install/terminal/a-shell.sh clones three repositories among
# the very first things a fresh install does -- it sorts first of the terminal
# installers, which run before the desktop ones -- so a network blip there ended
# the entire run before anything was installed. Same shape as the disabled cask,
# with a different cause.

# run_installer <home> <path under install/> <git: ok|fail> <curl: ok|fail>
# Source a real installer under `set -e` with the network blocked, so an abort
# shows up as the end marker going missing.
run_installer() {
  RUN_HOME="$1"
  RUN_SCRIPT="$2"
  RUN_GIT="$3"
  RUN_CURL="$4"

  TEST_OUTPUT=$(
    exec 2>&1
    set --
    HOME="$RUN_HOME"
    export HOME
    source "$OMAKMA_PATH/defaults/bash/functions"

    GIT_MODE="$RUN_GIT"
    CURL_MODE="$RUN_CURL"

    git() {
      if [ "$1" = clone ]; then
        if [ "$GIT_MODE" = ok ]; then
          # Enough of the LazyVim starter's layout for the installer to be
          # exercised rather than tripping over an empty directory.
          mkdir -p "$3/lua/plugins"
          return 0
        fi
        echo "clone refused" >&2
        return 1
      fi
      command git "$@"
    }
    curl() {
      if [ "$CURL_MODE" = ok ]; then
        # -o <file> is the last pair, as every caller here writes one.
        : >"${*##* }"
        return 0
      fi
      echo "curl refused" >&2
      return 1
    }
    wget() { return 1; }
    sh() { return 1; }
    app_install() { :; }
    # Succeeds, because these cases are about downloads rather than packages.
    # Failing it made them depend on whether the host happened to have the tool
    # already: app-neovim.sh only reaches `brew install` when nvim is not on
    # PATH, so the result differed between macOS and a CI runner.
    brew() { return 0; }

    set -e
    source "$OMAKMA_PATH/install/$RUN_SCRIPT"
    echo "reached_end=yes"
    echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
    report_failed_installs
  )
}

# sandbox_with_checkout <name>
# A sandbox HOME whose ~/.local/share/omakma points at this checkout, because
# a-shell.sh sources defaults/bash/shell, which resets OMAKMA_PATH to there.
sandbox_with_checkout() {
  local home
  home=$(sandbox_home "$1")

  mkdir -p "$home/.local/share"
  ln -sfn "$OMAKMA_PATH" "$home/.local/share/omakma"

  printf '%s' "$home"
}

echo "a-shell.sh survives every clone failing"
HOME_DIR=$(sandbox_with_checkout shell-clones-fail)
mkdir -p "$HOME_DIR/.oh-my-zsh/custom/plugins"
run_installer "$HOME_DIR" terminal/a-shell.sh fail ok
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "all three clones are recorded" "recorded=3"
assert_says "and named in the summary" "  - zsh-autosuggestions"
assert_exists "the shell config is still written" "$HOME_DIR/.zshrc"
assert_exists "and the bash config" "$HOME_DIR/.bashrc"

echo "a-shell.sh skips the plugins when Oh My Zsh itself did not install"
HOME_DIR=$(sandbox_with_checkout shell-ohmyzsh-fail)
run_installer "$HOME_DIR" terminal/a-shell.sh fail fail
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "it reports Oh My Zsh" "Could not download Oh My Zsh"
assert_says "and records only that, not the three plugins" "recorded=1"
case "$TEST_OUTPUT" in
*"clone refused"*) test_fail "it tried to clone into an Oh My Zsh that is not there" ;;
*) test_pass "no plugin clone is attempted" ;;
esac

echo "a-shell.sh reports an Oh My Zsh installer that downloads but will not run"
HOME_DIR=$(sandbox_with_checkout shell-ohmyzsh-broken)
run_installer "$HOME_DIR" terminal/a-shell.sh fail ok
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "it reports Oh My Zsh rather than succeeding silently" "Could not finish setting up Oh My Zsh"
assert_quiet "and not as a download problem, since the download worked" "Could not download Oh My Zsh"

echo "app-sublime.sh survives its seven clones and Package Control failing"
HOME_DIR=$(sandbox_home sublime-downloads-fail)
run_installer "$HOME_DIR" desktop/app-sublime.sh fail fail
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "all eight downloads are recorded" "recorded=8"
assert_says "Package Control is named" "  - Package Control"
assert_says "and so is a package" "  - LSP"

echo "app-neovim.sh stops configuring a clone that never arrived"
HOME_DIR=$(sandbox_home neovim-clone-fails)
run_installer "$HOME_DIR" terminal/app-neovim.sh fail fail
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "the clone is recorded" "Could not download LazyVim starter"
assert_gone "and no config is written into a directory that is not there" "$HOME_DIR/.config/nvim/lazyvim.json"

echo "a clone that works is configured as before"
HOME_DIR=$(sandbox_home neovim-clone-works)
run_installer "$HOME_DIR" terminal/app-neovim.sh ok fail
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "nothing is recorded" "recorded=0"
assert_exists "the theme is written" "$HOME_DIR/.config/nvim/lua/plugins/theme.lua"
assert_exists "and the extras" "$HOME_DIR/.config/nvim/lazyvim.json"

echo "clone_if_missing leaves a directory that is already there alone"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  git() {
    echo "clone attempted"
    return 1
  }
  mkdir -p "$TEST_SANDBOX/already-cloned"
  clone_if_missing "$TEST_SANDBOX/already-cloned" https://example.invalid/x.git
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
)
assert_says "returns success" "returned=0"
assert_says "nothing recorded" "recorded=0"
case "$TEST_OUTPUT" in
*"clone attempted"*) test_fail "it cloned over a directory that was already there" ;;
*) test_pass "no clone attempted" ;;
esac

echo "download_failed records and carries on"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  download_failed "something"
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
  report_failed_installs
)
assert_says "returns success so set -e cannot abort" "returned=0"
assert_says "it is recorded" "recorded=1"
assert_says "it says so at the point of failure" "Could not download something"
assert_says "the summary covers downloads as well as packages" "a download may have failed"

echo "setup_failed records the same way, without blaming the download"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  setup_failed "something"
  echo "returned=$?"
  echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
)
assert_says "returns success so set -e cannot abort" "returned=0"
assert_says "it is recorded" "recorded=1"
assert_says "it says what actually went wrong" "Could not finish setting up something"
assert_quiet "and does not call it a download" "Could not download"
