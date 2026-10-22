# boot.sh's first two steps: installing the Command Line Tools, and the clone.
#
# They cannot live in the repository the way install/pin-to-release.sh does,
# because boot.sh runs before the repository exists. So they are functions, and
# sourcing boot.sh with $OMAKMA_BOOT_DEFINE_ONLY defines them without running
# anything -- which is what makes them reachable from here at all.
#
# Nothing in these cases touches xcode-select, softwareupdate, sudo or the
# network: every one of those is stubbed, and the clone runs against a local
# repository built for the purpose.

# Resolved once here: referring to $OMAKMA_PATH from inside the subshells below
# reads to ShellCheck as modifying it in one.
BOOT_SH="$OMAKMA_PATH/boot.sh"

# A plausible `softwareupdate -l`, since the label is pulled out of it by a
# grep/tail/sed pipeline that had never been exercised.
SOFTWAREUPDATE_OUTPUT='Software Update Tool

Finding available software
Software Update found the following new or updated software:
* Label: Command Line Tools for Xcode-15.3
	Title: Command Line Tools for Xcode, Version: 15.3, Size: 700000KiB, Recommended: YES,
* Label: Command Line Tools for Xcode-16.0
	Title: Command Line Tools for Xcode, Version: 16.0, Size: 719859KiB, Recommended: YES,'

echo "sourcing boot.sh in define-only mode runs none of it"
TEST_OUTPUT=$(
  exec 2>&1
  OMAKMA_BOOT_DEFINE_ONLY=1
  export OMAKMA_BOOT_DEFINE_ONLY
  clear() { echo "CLEARED"; }
  git() { echo "CLONED"; }
  xcode-select() { echo "CHECKED"; }
  source "$BOOT_SH"
  echo "functions=$(declare -F | grep -cE 'install_xcode_clt|clone_omakma')"
)
assert_says "both steps are defined" "functions=2"
case "$TEST_OUTPUT" in
*CLEARED* | *CLONED* | *CHECKED*) test_fail "it ran part of the install just from being sourced" ;;
*) test_pass "and nothing is run" ;;
esac

echo "the Command Line Tools are left alone when they are already there"
TEST_OUTPUT=$(
  exec 2>&1
  OMAKMA_BOOT_DEFINE_ONLY=1
  export OMAKMA_BOOT_DEFINE_ONLY
  source "$BOOT_SH"

  # shellcheck disable=SC2032
  xcode-select() { return 0; }
  # shellcheck disable=SC2032
  softwareupdate() { echo "ASKED softwareupdate"; }
  sudo() { echo "ASKED sudo"; }
  touch() { :; }

  install_xcode_clt
  echo "returned=$?"
)
assert_says "it says they are installed" "already installed"
assert_says "and returns success" "returned=0"
case "$TEST_OUTPUT" in
*ASKED*) test_fail "it went looking for an update anyway" ;;
*) test_pass "softwareupdate is never asked" ;;
esac

echo "the label is taken from the last Command Line entry"
TEST_OUTPUT=$(
  exec 2>&1
  OMAKMA_BOOT_DEFINE_ONLY=1
  export OMAKMA_BOOT_DEFINE_ONLY
  source "$BOOT_SH"

  LISTING="$SOFTWAREUPDATE_OUTPUT"
  # install_xcode_clt also runs `sudo softwareupdate` and `sudo xcode-select`,
  # which could never reach a function -- sudo is stubbed instead, so these two
  # only stand in for the direct calls. SC2032 points that out, correctly.
  # shellcheck disable=SC2032
  xcode-select() { return 1; }
  # shellcheck disable=SC2032
  softwareupdate() { printf '%s\n' "$LISTING"; }
  sudo() {
    echo "sudo $*"
    return 0
  }
  touch() { :; }

  install_xcode_clt
  echo "returned=$?"
)
assert_says "the newest label is passed to softwareupdate, with no prefix left on it" "sudo softwareupdate --install Command Line Tools for Xcode-16.0 --verbose"
assert_says "and the tools are switched to" "sudo xcode-select --switch /Library/Developer/CommandLineTools"
assert_says "returning success" "returned=0"

echo "a listing with no Command Line Tools in it is fatal, and says why"
TEST_OUTPUT=$(
  exec 2>&1
  OMAKMA_BOOT_DEFINE_ONLY=1
  export OMAKMA_BOOT_DEFINE_ONLY
  source "$BOOT_SH"

  # shellcheck disable=SC2032
  xcode-select() { return 1; }
  # shellcheck disable=SC2032
  softwareupdate() { echo "No new software available."; }
  sudo() { echo "ASKED sudo"; }
  touch() { :; }

  install_xcode_clt
  echo "returned=$?"
)
assert_says "it says what it could not find" "Could not find Command Line Tools"
assert_says "and reports failure, which boot.sh exits on" "returned=1"
case "$TEST_OUTPUT" in
*"ASKED sudo"*) test_fail "it ran sudo with an empty label" ;;
*) test_pass "sudo is never reached" ;;
esac

echo "the clone replaces whatever was there"
BOOT_SOURCE="$TEST_SANDBOX/boot-source"
mkdir -p "$BOOT_SOURCE"
git init --quiet "$BOOT_SOURCE"
git -C "$BOOT_SOURCE" symbolic-ref HEAD refs/heads/master
echo "0.0.0" >"$BOOT_SOURCE/version"
git -C "$BOOT_SOURCE" add version
git -C "$BOOT_SOURCE" -c user.email=t@t -c user.name=t commit --quiet -m "a repository to clone"

BOOT_TARGET="$TEST_SANDBOX/boot-target"
mkdir -p "$BOOT_TARGET"
echo "stale" >"$BOOT_TARGET/LEFTOVER.md"

TEST_OUTPUT=$(
  exec 2>&1
  OMAKMA_BOOT_DEFINE_ONLY=1
  export OMAKMA_BOOT_DEFINE_ONLY
  OMAKMA_CLONE_URL="$BOOT_SOURCE"
  OMAKMA_CLONE_PATH="$BOOT_TARGET"
  source "$BOOT_SH"

  clone_omakma
  echo "returned=$?"
)
assert_says "it returns success" "returned=0"
assert_same "the clone is there" "$BOOT_TARGET/version" "$BOOT_SOURCE/version"
assert_gone "and whatever was there before is gone" "$BOOT_TARGET/LEFTOVER.md"

echo "a clone that fails reports it, which boot.sh exits on"
TEST_OUTPUT=$(
  exec 2>&1
  OMAKMA_BOOT_DEFINE_ONLY=1
  export OMAKMA_BOOT_DEFINE_ONLY
  OMAKMA_CLONE_URL="$TEST_SANDBOX/not-a-repository"
  OMAKMA_CLONE_PATH="$TEST_SANDBOX/boot-target-failed"
  source "$BOOT_SH"

  clone_omakma
  echo "returned=$?"
)
case "$TEST_OUTPUT" in
*"returned=0"*) test_fail "a failed clone reported success" ;;
*) test_pass "it reports failure" ;;
esac

echo "boot.sh stops on either step rather than carrying on"
BOOT_CONTENT=$(cat "$BOOT_SH")
case "$BOOT_CONTENT" in
*"install_xcode_clt || exit 1"*) test_pass "it exits if the Command Line Tools cannot be installed" ;;
*) test_fail "a failed Command Line Tools install no longer stops boot.sh" ;;
esac
case "$BOOT_CONTENT" in
*"clone_omakma || exit 1"*) test_pass "and exits if the clone fails" ;;
*) test_fail "a failed clone no longer stops boot.sh, so it sources paths that are not there" ;;
esac
