# What a failed Composer bootstrap does to an install.
#
# install/terminal/select-dev-language.sh fetched the Composer installer with
# `php -r "copy(...)"`, which exits 0 when the download fails and writes no
# file. The line after it then ran php against a file that was not there, and
# since install.sh runs under `set -e` with an ERR trap, the whole run ended at
# the retry message before install/desktop.sh had been reached -- no desktop
# apps, no Dock, no themes, no fonts. PHP is preselected in
# install/first-run-choices.sh, so that was the default path on a bad
# connection. The `composer global require` / `valet install` / `valet trust`
# chain below it was unguarded for the same reason.
#
# These cases source the real installer under `set -e` and check that each way
# the bootstrap can fail is recorded and survived rather than aborting, and that
# neither the setup script nor the phar is left in the directory the install was
# started from.

# The body the stubbed curl serves as the installer, and the hash the stubbed
# php reports for it. Both are fixtures on purpose: what is under test is that
# the installer compares the two sides and refuses to run the installer when
# they differ, not that PHP can compute a sha384. Hashing for real would mean
# the cases needed a hash tool on the machine running them, and plain Ubuntu has
# no shasum -- the fourth time this suite would have read the host instead of
# being told.
COMPOSER_BODY='installer-contents'
COMPOSER_SIG='0ff1ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'

# language_defaults
# Every step succeeding, with only php already installed, so each case can set
# the one thing it is about. PRESENT is what `command -v` finds; composer and
# valet are absent to begin with, which is what sends the installer into both
# bootstraps.
language_defaults() {
  CURL_MODE=ok
  SIG_MODE=ok
  PHP_MODE=ok
  SUDO_MODE=ok
  REQUIRE_MODE=ok
  VALET_INSTALL_MODE=ok
  VALET_TRUST_MODE=ok
  PRESENT=php
}

# run_language <home>
# Source the real installer with PHP as the only selected language, under
# `set -e`, with everything it reaches for stubbed. An abort shows up as the end
# marker going missing.
run_language() {
  RUN_HOME="$1"

  TEST_OUTPUT=$(
    exec 2>&1
    set --
    HOME="$RUN_HOME"
    export HOME

    # mktemp -d has to land inside the sandbox, which is removed on exit, and
    # somewhere the cwd check below cannot see.
    TMPDIR="$RUN_HOME/tmp"
    export TMPDIR
    mkdir -p "$TMPDIR" "$RUN_HOME/work"

    # Stand in for the directory the user ran the one-liner from. Nothing in
    # install.sh ever cd's, so this is where the old bootstrap wrote
    # composer-setup.php and composer.phar.
    cd "$RUN_HOME/work"

    source "$OMAKMA_PATH/defaults/bash/functions"

    OMAKMA_FIRST_RUN_LANGUAGES=PHP

    # `command -v` is how the installer decides what is already there, so these
    # cases decide for it. Letting it read the host would put whether php,
    # composer or valet happens to be installed on the machine running the suite
    # in charge of which branches run -- which has caught this suite out three
    # times already.
    # `command -v` is how the installer decides what is already there, so these
    # cases decide for it. Letting it read the host would put whether php,
    # composer or valet happens to be installed on the machine running the suite
    # in charge of which branches run -- which has caught this suite out three
    # times already.
    #
    # Every stub here matches with [[ ]] rather than `case`: bash 3.2 mis-parses
    # a case pattern's closing paren inside a command substitution, and all of
    # this lives inside one.
    command() {
      if [ "$1" = -v ]; then
        if [[ " $PRESENT " == *" $2 "* ]]; then
          echo "$2"
          return 0
        fi

        return 1
      fi

      builtin command "$@"
    }

    curl() {
      local arg
      local out=""
      local url=""
      local prev=""

      for arg in "$@"; do
        if [ "$prev" = -o ]; then out="$arg"; fi
        if [[ "$arg" == https://* ]]; then url="$arg"; fi
        prev="$arg"
      done

      if [[ "$url" == *installer.sig ]]; then
        if [ "$SIG_MODE" = fail ]; then
          echo "curl refused $url" >&2
          return 1
        fi

        if [ "$SIG_MODE" = bad ]; then
          printf 'not-the-published-checksum' >"$out"
        else
          printf '%s' "$COMPOSER_SIG" >"$out"
        fi

        return 0
      fi

      if [ "$CURL_MODE" = fail ]; then
        echo "curl refused $url" >&2
        return 1
      fi

      printf '%s' "$COMPOSER_BODY" >"$out"
    }

    php() {
      local arg
      local dir=""

      # The hash the installer checks the download against. Answered rather
      # than computed, so the comparison is exercised without the cases needing
      # a hash tool of their own.
      if [ "$1" = -r ]; then
        printf '%s' "$COMPOSER_SIG"
        return 0
      fi

      for arg in "$@"; do
        if [[ "$arg" == --install-dir=* ]]; then dir="${arg#--install-dir=}"; fi
      done

      echo "the installer was run"

      if [ "$PHP_MODE" = fail ]; then
        echo "installer failed" >&2
        return 1
      fi

      : >"$dir/composer"
    }

    sudo() {
      if [ "$SUDO_MODE" = fail ]; then
        echo "sudo refused" >&2
        return 1
      fi

      # Landing in /usr/local/bin is what puts composer on PATH for the rest of
      # the script, so say so rather than touching the real directory.
      if [ "$1" = mv ]; then
        PRESENT="$PRESENT composer"
      fi

      return 0
    }

    composer() {
      if [ "$1" = global ]; then
        if [ "$REQUIRE_MODE" = fail ]; then
          echo "require refused" >&2
          return 1
        fi

        # orphan: the require reports success but nothing reaches PATH.
        if [ "$REQUIRE_MODE" != orphan ]; then
          PRESENT="$PRESENT valet"
        fi
      fi

      return 0
    }

    valet() {
      if [ "$1" = install ] && [ "$VALET_INSTALL_MODE" = fail ]; then
        echo "valet install refused" >&2
        return 1
      fi

      if [ "$1" = trust ] && [ "$VALET_TRUST_MODE" = fail ]; then
        echo "valet trust refused" >&2
        return 1
      fi

      return 0
    }

    brew() { return 0; }
    mise() { return 0; }

    set -e
    source "$OMAKMA_PATH/install/terminal/select-dev-language.sh"
    echo "reached_end=yes"
    echo "recorded=${#OMAKMA_FAILED_INSTALLS[@]}"
    echo "cwd_entries=$(find . -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
    echo "tmp_entries=$(find "$TMPDIR" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
    report_failed_installs
  )
}

# assert_quiet <description> <substring>
# The other side of assert_says: something the run must not have done.
assert_quiet() {
  case "$TEST_OUTPUT" in
  *"$2"*) test_fail "$1 (in output: $2)" ;;
  *) test_pass "$1" ;;
  esac
}

echo "a Composer installer that will not download is skipped, not fatal"
language_defaults
CURL_MODE=fail
run_language "$(sandbox_home dev-language-curl)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "Composer is recorded" "recorded=1"
assert_says "it says so at the point of failure" "Could not download Composer"
assert_quiet "the installer is not run against a file that is not there" "the installer was run"
assert_says "and Valet says why it was skipped too" "Skipping Valet: Composer is not available."
assert_says "nothing is left in the directory the install started from" "cwd_entries=0"
assert_says "and the temp directory is cleaned up" "tmp_entries=0"

echo "a signature that will not download is skipped too"
language_defaults
SIG_MODE=fail
run_language "$(sandbox_home dev-language-sig)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "Composer is recorded" "recorded=1"
assert_quiet "the installer is not run unchecked" "the installer was run"
assert_says "and the temp directory is cleaned up" "tmp_entries=0"

echo "an installer that does not match its published checksum is not run"
language_defaults
SIG_MODE=bad
run_language "$(sandbox_home dev-language-checksum)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "Composer is recorded" "recorded=1"
assert_says "it says what was wrong" "did not match its published checksum"
assert_quiet "and the installer is never executed" "the installer was run"
assert_says "the temp directory is cleaned up" "tmp_entries=0"

echo "an installer that downloads and then fails is reported as a setup failure"
language_defaults
PHP_MODE=fail
run_language "$(sandbox_home dev-language-run)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "Composer is recorded" "recorded=1"
assert_says "it was reached" "the installer was run"
assert_says "and not reported as a download problem" "Could not finish setting up Composer"
assert_quiet "since the download worked" "Could not download Composer"
assert_says "the temp directory is cleaned up" "tmp_entries=0"

echo "a phar that cannot be moved into place is skipped, not fatal"
language_defaults
SUDO_MODE=fail
run_language "$(sandbox_home dev-language-sudo)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "Composer is recorded" "recorded=1"
assert_says "it says so" "Could not finish setting up Composer"
assert_says "the temp directory is cleaned up" "tmp_entries=0"

echo "a bootstrap that works installs Valet and records nothing"
language_defaults
run_language "$(sandbox_home dev-language-works)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "nothing is recorded" "recorded=0"
assert_says "the installer was reached" "the installer was run"
assert_quiet "and Valet is not skipped" "Skipping Valet"
assert_says "the phar is not left in the directory the install started from" "cwd_entries=0"
assert_says "and the temp directory is cleaned up" "tmp_entries=0"

echo "a Valet require that fails is skipped, not fatal"
language_defaults
REQUIRE_MODE=fail
run_language "$(sandbox_home dev-language-require)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "Valet is recorded" "recorded=1"
assert_says "it says so" "Could not download Valet"

echo "a Valet that does not reach PATH is reported rather than run"
language_defaults
REQUIRE_MODE=orphan
run_language "$(sandbox_home dev-language-orphan)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "Valet is recorded" "recorded=1"
assert_says "it says what happened" "is not on PATH"
assert_says "as a setup failure" "Could not finish setting up Valet"

echo "a valet install that fails is skipped, not fatal"
language_defaults
VALET_INSTALL_MODE=fail
run_language "$(sandbox_home dev-language-valet-install)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "Valet is recorded" "recorded=1"
assert_says "it says so" "Could not finish setting up Valet"

echo "a valet trust that fails is a note rather than a skipped install"
language_defaults
VALET_TRUST_MODE=fail
run_language "$(sandbox_home dev-language-valet-trust)"
assert_says "the installer runs to the end" "reached_end=yes"
assert_says "nothing is recorded, since Valet itself installed" "recorded=0"
assert_says "but the user is told what they will see" "will ask for your password"
