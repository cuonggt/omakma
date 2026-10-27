# Whether the optional-apps selector asks, and when it must not.
#
# install/desktop/select-optional-apps.sh tested OMAKMA_FIRST_RUN_OPTIONAL_APPS
# for being non-empty and had no prompt to fall back on, so browsing to it
# through `omakma install` silently installed nothing while its two siblings
# would have asked. Adding the prompt is what makes the set-versus-non-empty
# distinction load-bearing: an empty value is the user having chosen none of
# them on first run, and reading that as "never asked" asks again part-way
# through an install that is already running -- the exact trap CLAUDE.md
# records against these three scripts.

# run_optional_apps <home> <chosen|unset> <value>
# For "chosen", <value> is what first-run-choices.sh exported, "" included. For
# "unset", the variable is not there and <value> is what the prompt returns.
run_optional_apps() {
  RUN_HOME="$1"
  RUN_MODE="$2"
  RUN_VALUE="$3"

  TEST_OUTPUT=$(
    exec 2>&1
    set --
    HOME="$RUN_HOME"
    export HOME
    source "$OMAKMA_PATH/defaults/bash/functions"

    if [ "$RUN_MODE" = unset ]; then
      unset OMAKMA_FIRST_RUN_OPTIONAL_APPS
      GUM_CHOICES="$RUN_VALUE"
    else
      OMAKMA_FIRST_RUN_OPTIONAL_APPS="$RUN_VALUE"
      export OMAKMA_FIRST_RUN_OPTIONAL_APPS
      GUM_CHOICES="the prompt should not have been reached"
    fi

    # Announced as well as answered, so a case can assert that nothing asked.
    # The announcement goes to stderr: the selector reads gum inside a command
    # substitution, so anything on stdout becomes part of the answer -- it was
    # read back as an app name and sourced as a path that is not there.
    # `exec 2>&1` above is what still brings it into TEST_OUTPUT.
    gum() {
      echo "PROMPTED: $*" >&2
      printf '%s\n' "$GUM_CHOICES"
    }

    # Every optional installer is a single app_install call, so reporting that
    # is reporting which ones ran.
    app_install() { echo "INSTALL: $1"; }
    brew() { return 0; }

    # The install path this script runs on.
    set -e
    source "$OMAKMA_PATH/install/desktop/select-optional-apps.sh"
    echo "reached_end=yes"
  )
}

echo "the apps chosen on first run are installed without asking again"
HOME_DIR=$(sandbox_home optional-chosen)
run_optional_apps "$HOME_DIR" chosen "$(printf '1111\nDropbox')"
assert_says "it runs to the end" "reached_end=yes"
assert_says "the first choice is installed" "INSTALL: cloudflare-warp"
assert_says "and the second" "INSTALL: dropbox"
assert_quiet "nothing is asked, since the choice was already made" "PROMPTED"

echo "choosing none of them on first run installs none and asks nothing"
HOME_DIR=$(sandbox_home optional-none)
run_optional_apps "$HOME_DIR" chosen ""
assert_says "it runs to the end" "reached_end=yes"
assert_quiet "nothing is installed" "INSTALL:"
assert_quiet "and the install is not interrupted to ask again" "PROMPTED"

echo "reaching it with nothing chosen asks, rather than doing nothing quietly"
HOME_DIR=$(sandbox_home optional-unset)
run_optional_apps "$HOME_DIR" unset "Xmind"
assert_says "it runs to the end" "reached_end=yes"
assert_says "it asks" "PROMPTED"
assert_says "with its own header" "Select optional apps"
assert_says "and installs what was picked" "INSTALL: xmind"

echo "a prompt the user escapes installs nothing"
HOME_DIR=$(sandbox_home optional-escaped)
run_optional_apps "$HOME_DIR" unset ""
assert_says "it runs to the end" "reached_end=yes"
assert_says "it asked" "PROMPTED"
assert_quiet "but installed nothing" "INSTALL:"

echo "the label is lowercased to find the installer, whatever its casing"
HOME_DIR=$(sandbox_home optional-casing)
run_optional_apps "$HOME_DIR" chosen "$(printf 'Pritunl\nXmind')"
assert_says "Pritunl resolves" "INSTALL: pritunl"
assert_says "Xmind resolves" "INSTALL: xmind"
assert_quiet "and nothing failed to source" "No such file or directory"

echo "every label the first-run prompt offers has an installer behind it"
# Read out of install/first-run-choices.sh rather than restated here, so a label
# added there without an installer fails this rather than a user's install.
OPTIONAL_LABELS=$(sed -n 's/^OPTIONAL_APPS=(\(.*\))$/\1/p' "$OMAKMA_PATH/install/first-run-choices.sh" | tr -d '"')
assert_parsed "the labels are read out of first-run-choices.sh" "$OPTIONAL_LABELS"
for OPTIONAL_LABEL in $OPTIONAL_LABELS; do
  OPTIONAL_SLUG=$(printf '%s' "$OPTIONAL_LABEL" | tr '[:upper:]' '[:lower:]')
  assert_exists "$OPTIONAL_LABEL has an installer" "$OMAKMA_PATH/install/desktop/optional/app-$OPTIONAL_SLUG.sh"
  assert_exists "$OPTIONAL_LABEL has an uninstaller" "$OMAKMA_PATH/uninstall/desktop/optional/app-$OPTIONAL_SLUG.sh"
done
