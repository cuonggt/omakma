# That the keep-awake cannot outlive the install.
#
# install/terminal.sh and install/desktop.sh used to background `caffeinate` and
# kill it after their installer loop. Under `set -e` any failure in the loop
# skipped the kill, so the process survived the install and held the Mac awake
# indefinitely with nothing on screen to say so. Verified by reproducing it
# before the fix: the script exited 1, the kill never ran, and the process had
# to be killed by hand.
#
# `caffeinate` is stubbed as `exec sleep`, so the recorded pid is the stand-in
# itself and these cases never actually stop the machine idling. Each runs in a
# subshell with its output redirected, both to keep the EXIT trap out of the
# test runner and so the background process holds no pipe open.

# gone_within <pid>
# True once the process disappears, allowing for the moment between the kill
# and the process being reaped.
gone_within() {
  local pid="$1"
  local waited=0

  while [ "$waited" -lt 30 ]; do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.1
    waited=$((waited + 1))
  done

  return 1
}

# assert_stopped <description> <pidfile>
assert_stopped() {
  local pid
  pid=$(cat "$2" 2>/dev/null)

  if [ -z "$pid" ]; then
    test_fail "$1 (no pid was recorded)"
    return 0
  fi

  if gone_within "$pid"; then
    test_pass "$1"
  else
    test_fail "$1 (pid $pid is still running)"
    kill "$pid" 2>/dev/null
  fi
}

echo "let_sleep stops what keep_awake started"
PID_FILE="$TEST_SANDBOX/keep-awake-normal.pid"
(
  source "$OMAKMA_PATH/defaults/bash/functions"
  caffeinate() { exec sleep 30; }
  keep_awake
  echo "$OMAKMA_CAFFEINATE_PID" >"$PID_FILE"
  let_sleep
) >/dev/null 2>&1
assert_stopped "the keep-awake is stopped" "$PID_FILE"

echo "an abort in the installer loop still stops it"
PID_FILE="$TEST_SANDBOX/keep-awake-abort.pid"
(
  source "$OMAKMA_PATH/defaults/bash/functions"
  caffeinate() { exec sleep 30; }
  set -e
  keep_awake
  echo "$OMAKMA_CAFFEINATE_PID" >"$PID_FILE"

  # What install/desktop.sh's loop does when an installer fails.
  for installer in a b c; do
    if [ "$installer" = a ]; then
      false
    fi
  done

  let_sleep
) >/dev/null 2>&1
assert_stopped "the EXIT trap stops it even though let_sleep was never reached" "$PID_FILE"

echo "two installer loops in a row leave nothing behind"
PID_FILE="$TEST_SANDBOX/keep-awake-first.pid"
PID_FILE_TWO="$TEST_SANDBOX/keep-awake-second.pid"
(
  source "$OMAKMA_PATH/defaults/bash/functions"
  caffeinate() { exec sleep 30; }
  set -e

  # install/terminal.sh
  keep_awake
  echo "$OMAKMA_CAFFEINATE_PID" >"$PID_FILE"
  let_sleep

  # install/desktop.sh, which aborts
  keep_awake
  echo "$OMAKMA_CAFFEINATE_PID" >"$PID_FILE_TWO"
  false
) >/dev/null 2>&1
assert_stopped "the first loop's keep-awake is stopped" "$PID_FILE"
assert_stopped "and so is the second's, by the re-armed trap" "$PID_FILE_TWO"

echo "let_sleep is safe to call when there is nothing to stop"
TEST_OUTPUT=$(
  exec 2>&1
  source "$OMAKMA_PATH/defaults/bash/functions"
  let_sleep
  echo "first=$?"
  let_sleep
  echo "second=$?"
)
assert_says "returns success with nothing started" "first=0"
assert_says "and again when called twice" "second=0"
case "$TEST_OUTPUT" in
*"No such process"* | *"not a pid"*) test_fail "it complained about a pid that was never there" ;;
*) test_pass "it says nothing" ;;
esac

echo "neither installer loop kills a pid by hand any more"
for LOOP_FILE in install/terminal.sh install/desktop.sh; do
  LOOP_CONTENT=$(cat "$OMAKMA_PATH/$LOOP_FILE")

  case "$LOOP_CONTENT" in
  *keep_awake*) test_pass "$LOOP_FILE arms the keep-awake through keep_awake" ;;
  *) test_fail "$LOOP_FILE does not call keep_awake" ;;
  esac

  # Matching the variable name rather than the kill catches a reassignment too.
  case "$LOOP_CONTENT" in
  *CAFFEINATE_PID*) test_fail "$LOOP_FILE handles a caffeinate pid itself, so an abort leaks it" ;;
  *) test_pass "$LOOP_FILE holds no caffeinate pid of its own" ;;
  esac
done
