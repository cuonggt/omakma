# Whether a tap gets removed on uninstall, and more importantly when it does not.
#
# `brew untap` on a tap that still has packages installed offers to uninstall
# them and prompts while doing it, so untap_if_unused has to establish that
# nothing is left from the tap before going anywhere near it. These cases stub
# `brew` so the decision can be read off what it was asked to do.

# brew_stub <taps> <installed>
# Writes a brew stub into $TEST_SANDBOX that reports the given `brew tap` and
# `brew list --full-name` output and records any untap it is asked for.
UNTAP_LOG="$TEST_SANDBOX/untap.log"

echo "a tap with nothing installed from it is removed"
: >"$UNTAP_LOG"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() {
    if [ "$1" = tap ]; then
      printf '%s\n' localsend/localsend homebrew/cask
    elif [ "$1" = list ]; then
      printf '%s\n' wget shivammathur/php/php@8.3
    elif [ "$1" = untap ]; then
      echo "$2" >>"$UNTAP_LOG"
      echo "Untapped $2"
    fi
  }
  untap_if_unused localsend/localsend
  echo "returned=$?"
)
assert_says "returns success" "returned=0"
assert_says "the tap is untapped" "Untapped localsend/localsend"
if [ "$(cat "$UNTAP_LOG")" = "localsend/localsend" ]; then
  test_pass "brew untap was asked for exactly that tap"
else
  test_fail "untap was asked for: [$(cat "$UNTAP_LOG")]"
fi

echo "a tap with something still installed from it is kept"
: >"$UNTAP_LOG"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() {
    if [ "$1" = tap ]; then
      printf '%s\n' shivammathur/php
    elif [ "$1" = list ]; then
      printf '%s\n' wget shivammathur/php/php@8.3
    elif [ "$1" = untap ]; then
      echo "$2" >>"$UNTAP_LOG"
    fi
  }
  untap_if_unused shivammathur/php
  echo "returned=$?"
)
assert_says "returns success" "returned=0"
assert_says "it names what is keeping the tap" "Kept the shivammathur/php tap: shivammathur/php/php@8.3 is still installed"
if [ ! -s "$UNTAP_LOG" ]; then
  test_pass "brew untap is never reached, so nothing can be uninstalled by it"
else
  test_fail "it tried to untap a tap with packages installed"
fi

echo "a tap that is not there at all is left alone, quietly"
: >"$UNTAP_LOG"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() {
    if [ "$1" = tap ]; then
      printf '%s\n' homebrew/cask
    elif [ "$1" = list ]; then
      printf '%s\n' wget
    elif [ "$1" = untap ]; then
      echo "$2" >>"$UNTAP_LOG"
    fi
  }
  untap_if_unused localsend/localsend
  echo "returned=$?"
)
assert_says "returns success" "returned=0"
if [ ! -s "$UNTAP_LOG" ]; then
  test_pass "no untap attempted"
else
  test_fail "it tried to untap a tap that was not installed"
fi
case "$TEST_OUTPUT" in
*Kept*) test_fail "it reported keeping a tap that was never there" ;;
*) test_pass "and says nothing about it" ;;
esac

echo "a tap name that is a prefix of another is not confused with it"
: >"$UNTAP_LOG"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() {
    if [ "$1" = tap ]; then
      printf '%s\n' oven-sh/bun
    elif [ "$1" = list ]; then
      # From a different tap whose name starts the same way.
      printf '%s\n' oven-sh/bun-extras/something
    elif [ "$1" = untap ]; then
      echo "$2" >>"$UNTAP_LOG"
      echo "Untapped $2"
    fi
  }
  untap_if_unused oven-sh/bun
)
assert_says "the lookalike does not keep the tap alive" "Untapped oven-sh/bun"

echo "a failed untap says so rather than passing silently"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  brew() {
    if [ "$1" = tap ]; then
      printf '%s\n' localsend/localsend
    elif [ "$1" = list ]; then
      printf '%s\n' wget
    elif [ "$1" = untap ]; then
      return 1
    fi
  }
  untap_if_unused localsend/localsend
  echo "returned=$?"
)
assert_says "it reports the failure" "Could not untap localsend/localsend"
assert_says "but does not stop the uninstaller" "returned=0"

echo "each app untaps its own tap, and nothing untaps shivammathur/php"
UNTAP_EXPECTED="uninstall/desktop/app-localsend.sh localsend/localsend
uninstall/desktop/app-phpmon.sh nicoverbruggen/cask
uninstall/terminal/app-lazydocker.sh jesseduffield/lazydocker
uninstall/terminal/app-bun.sh oven-sh/bun"

while IFS=' ' read -r UNTAP_FILE UNTAP_TAP; do
  UNTAP_CONTENT=$(cat "$OMAKMA_PATH/$UNTAP_FILE")

  case "$UNTAP_CONTENT" in
  *"untap_if_unused $UNTAP_TAP"*) test_pass "$UNTAP_FILE untaps $UNTAP_TAP" ;;
  *) test_fail "$UNTAP_FILE does not untap $UNTAP_TAP" ;;
  esac
done <<<"$UNTAP_EXPECTED"

for UNTAP_FILE in $(cd "$OMAKMA_PATH" && find uninstall -name '*.sh'); do
  case "$(cat "$OMAKMA_PATH/$UNTAP_FILE")" in
  *"untap_if_unused shivammathur/php"*)
    test_fail "$UNTAP_FILE untaps shivammathur/php, which omakma install needs"
    ;;
  esac
done
test_pass "no uninstaller untaps shivammathur/php"
