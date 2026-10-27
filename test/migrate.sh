# The migration mechanism: which migrations run, in what order, what a failing
# one does, and which ones a fresh install is spared.
#
# bin/omakma-sub/migrate.sh decides what reaches a machine that is already
# installed: a fix made inside an installer only ever helps machines set up
# after it, so everything else goes through here. install/preflight.sh is the
# other half -- it marks every migration that exists before the installers run,
# so a fresh machine is not put through fixes for problems it never had. Neither
# had any coverage; blanking either left the suite green.
#
# Both halves are here rather than in a file each, because the property worth
# holding on to spans them: preflight marks what exists, and migrate then runs
# only what is not marked. Testing either alone would miss it. `test/run.sh
# migrate` runs the lot.
#
# The migrations here are written into a throwaway OMAKMA_PATH, so nothing in
# the repository's own migrations/ directory runs.

# Resolved once, out here. Both runners set OMAKMA_PATH inside their own command
# substitution, and ShellCheck cannot tell that reading the outer value
# afterwards is deliberate rather than a lost write (SC2030/SC2031).
MIGRATE_CHECKOUT="$OMAKMA_PATH"

# new_migrate_sandbox <name>
# A throwaway OMAKMA_PATH with an empty migrations directory and a HOME for the
# default state path to land in.
new_migrate_sandbox() {
  local dir="$TEST_SANDBOX/$1"

  mkdir -p "$dir/migrations" "$dir/home"
  printf '%s' "$dir"
}

# write_migration <dir> <filename> <tag> [fail]
# A migration that records having run, and optionally fails afterwards.
write_migration() {
  local dir="$1"
  local name="$2"
  local tag="$3"
  local fail="${4:-}"

  cat >"$dir/migrations/$name" <<MIGRATION
printf '%s\n' "ran $tag" >>"$dir/order.log"
MIGRATION

  if [ "$fail" = fail ]; then
    printf 'return 1 2>/dev/null || exit 1\n' >>"$dir/migrations/$name"
  fi
}

# run_migrate <dir> [state-home]
# Source the real runner against a throwaway OMAKMA_PATH. With no state-home,
# OMAKMA_STATE_HOME and XDG_STATE_HOME are both unset so the default under HOME
# is what gets exercised.
run_migrate() {
  RUN_DIR="$1"
  RUN_STATE="${2:-}"

  TEST_OUTPUT=$(
    exec 2>&1
    set --
    HOME="$RUN_DIR/home"
    export HOME
    OMAKMA_PATH="$RUN_DIR"
    export OMAKMA_PATH

    if [ -n "$RUN_STATE" ]; then
      OMAKMA_STATE_HOME="$RUN_STATE"
      export OMAKMA_STATE_HOME
    else
      unset OMAKMA_STATE_HOME
      unset XDG_STATE_HOME
    fi

    # Branched on rather than read from `$?`: the runner ends in a for loop, so
    # its status describes whatever that loop last did.
    if source "$MIGRATE_CHECKOUT/bin/omakma-sub/migrate.sh"; then
      echo "returned=0"
    else
      echo "returned=1"
    fi

    # Whether a migration could reach the shell that ran it. They are sourced
    # inside ( ), which is what keeps one from changing the directory or the
    # variables the rest of the run depends on.
    echo "leak=${OMAKMA_MIGRATION_LEAK:-none}"
    echo "cwd=$(pwd)"
  )
}

# run_preflight <dir> [state-home]
# Source the real preflight against a throwaway OMAKMA_PATH, the way install.sh
# does before any installer runs.
run_preflight() {
  RUN_DIR="$1"
  RUN_STATE="${2:-}"

  TEST_OUTPUT=$(
    exec 2>&1
    set --
    HOME="$RUN_DIR/home"
    export HOME
    OMAKMA_PATH="$RUN_DIR"
    export OMAKMA_PATH

    if [ -n "$RUN_STATE" ]; then
      OMAKMA_STATE_HOME="$RUN_STATE"
      export OMAKMA_STATE_HOME
    else
      unset OMAKMA_STATE_HOME
      unset XDG_STATE_HOME
    fi

    if source "$MIGRATE_CHECKOUT/install/preflight.sh"; then
      echo "returned=0"
    else
      echo "returned=1"
    fi
  )
}

echo "a pending migration runs and is recorded"
MIG_DIR=$(new_migrate_sandbox migrate-pending)
write_migration "$MIG_DIR" 1700000000_first.sh first
run_migrate "$MIG_DIR"
assert_says "it names the migration" "Running migration: 1700000000_first.sh"
assert_says "and returns success" "returned=0"
assert_exists "the migration ran" "$MIG_DIR/order.log"
assert_exists "and its marker is written" "$MIG_DIR/home/.local/state/omakma/migrations/1700000000_first.sh"

echo "a migration already marked is left alone"
MIG_DIR=$(new_migrate_sandbox migrate-marked)
write_migration "$MIG_DIR" 1700000000_first.sh first
mkdir -p "$MIG_DIR/home/.local/state/omakma/migrations"
touch "$MIG_DIR/home/.local/state/omakma/migrations/1700000000_first.sh"
run_migrate "$MIG_DIR"
assert_says "it returns success" "returned=0"
assert_quiet "without naming the migration" "Running migration"
assert_gone "and without running it" "$MIG_DIR/order.log"

echo "migrations run in timestamp order, not the order they were written"
MIG_DIR=$(new_migrate_sandbox migrate-order)
write_migration "$MIG_DIR" 1800000000_second.sh second
write_migration "$MIG_DIR" 1700000000_first.sh first
run_migrate "$MIG_DIR"
assert_says "it returns success" "returned=0"
if [ "$(cat "$MIG_DIR/order.log")" = "$(printf 'ran first\nran second')" ]; then
  test_pass "the older migration runs first"
else
  test_fail "they ran out of order: $(tr '\n' ' ' <"$MIG_DIR/order.log")"
fi

echo "a failing migration stops the run and is not recorded"
MIG_DIR=$(new_migrate_sandbox migrate-failing)
write_migration "$MIG_DIR" 1700000000_ok.sh ok
write_migration "$MIG_DIR" 1750000000_bad.sh bad fail
write_migration "$MIG_DIR" 1800000000_later.sh later
MIG_STATE="$MIG_DIR/home/.local/state/omakma/migrations"
run_migrate "$MIG_DIR"
assert_says "it names the one that failed" "Migration failed: 1750000000_bad.sh"
assert_says "and reports failure, so omakma update cannot claim success" "returned=1"
assert_exists "the one before it is still recorded" "$MIG_STATE/1700000000_ok.sh"
assert_gone "the failing one is not recorded, so it runs again next time" "$MIG_STATE/1750000000_bad.sh"
assert_quiet "and the run stops rather than carrying on past it" "Running migration: 1800000000_later.sh"
assert_gone "so the later one neither ran" "$MIG_STATE/1800000000_later.sh"
if [ "$(cat "$MIG_DIR/order.log")" = "$(printf 'ran ok\nran bad')" ]; then
  test_pass "exactly the migrations up to the failure ran"
else
  test_fail "the wrong set ran: $(tr '\n' ' ' <"$MIG_DIR/order.log")"
fi

echo "no migrations at all is success, not an error"
MIG_DIR=$(new_migrate_sandbox migrate-none)
run_migrate "$MIG_DIR"
assert_says "it returns success" "returned=0"
assert_quiet "with nothing to say" "Running migration"
assert_exists "the state directory is still created" "$MIG_DIR/home/.local/state/omakma/migrations"

echo "a file that is not a migration is ignored"
MIG_DIR=$(new_migrate_sandbox migrate-nonsh)
write_migration "$MIG_DIR" 1700000000_real.sh real
printf 'printf "ran notes\\n" >>"%s/order.log"\n' "$MIG_DIR" >"$MIG_DIR/migrations/notes.txt"
run_migrate "$MIG_DIR"
assert_says "it returns success" "returned=0"
if [ "$(cat "$MIG_DIR/order.log")" = "ran real" ]; then
  test_pass "only the .sh file ran"
else
  test_fail "it ran something it should not have: $(tr '\n' ' ' <"$MIG_DIR/order.log")"
fi

echo "a migration cannot change the shell that ran it"
MIG_DIR=$(new_migrate_sandbox migrate-isolated)
cat >"$MIG_DIR/migrations/1700000000_meddle.sh" <<'MIGRATION'
OMAKMA_MIGRATION_LEAK=leaked
export OMAKMA_MIGRATION_LEAK
cd /
MIGRATION
run_migrate "$MIG_DIR"
assert_says "it returns success" "returned=0"
assert_says "nothing it set is visible afterwards" "leak=none"
assert_quiet "the value does not escape the subshell" "leak=leaked"
assert_quiet "nor does the directory it changed to" "cwd=/
"

echo "OMAKMA_STATE_HOME decides where the markers go"
MIG_DIR=$(new_migrate_sandbox migrate-state-home)
write_migration "$MIG_DIR" 1700000000_first.sh first
run_migrate "$MIG_DIR" "$MIG_DIR/elsewhere"
assert_says "it returns success" "returned=0"
assert_exists "the marker lands under it" "$MIG_DIR/elsewhere/migrations/1700000000_first.sh"
assert_gone "and not under HOME" "$MIG_DIR/home/.local/state/omakma/migrations/1700000000_first.sh"

echo "preflight marks every migration that already exists"
MIG_DIR=$(new_migrate_sandbox preflight-marks)
write_migration "$MIG_DIR" 1700000000_first.sh first
write_migration "$MIG_DIR" 1800000000_second.sh second
MIG_STATE="$MIG_DIR/home/.local/state/omakma/migrations"
run_preflight "$MIG_DIR"
assert_says "it returns success" "returned=0"
assert_exists "the state directory is created" "$MIG_STATE"
assert_exists "the first is marked" "$MIG_STATE/1700000000_first.sh"
assert_exists "and the second" "$MIG_STATE/1800000000_second.sh"
assert_gone "without running either of them" "$MIG_DIR/order.log"

echo "so a fresh install is put through none of them"
# The property the whole mechanism exists for, and the reason both halves are
# tested in one file: either on its own would pass while this broke.
MIG_DIR=$(new_migrate_sandbox preflight-then-migrate)
write_migration "$MIG_DIR" 1700000000_first.sh first
write_migration "$MIG_DIR" 1800000000_second.sh second
run_preflight "$MIG_DIR"
run_migrate "$MIG_DIR"
assert_says "the migration run succeeds" "returned=0"
assert_quiet "and names nothing, because nothing is pending" "Running migration"
assert_gone "no migration ran on the clean machine" "$MIG_DIR/order.log"

echo "a migration added after the install still runs"
# The complement: preflight marks what exists when it runs, not for all time,
# or no fix would ever reach a machine again.
MIG_DIR=$(new_migrate_sandbox preflight-then-new)
write_migration "$MIG_DIR" 1700000000_first.sh first
run_preflight "$MIG_DIR"
write_migration "$MIG_DIR" 1900000000_added_later.sh added_later
run_migrate "$MIG_DIR"
assert_says "the migration run succeeds" "returned=0"
assert_says "the new one is named" "Running migration: 1900000000_added_later.sh"
assert_quiet "and the pre-existing one is not" "Running migration: 1700000000_first.sh"
if [ "$(cat "$MIG_DIR/order.log")" = "ran added_later" ]; then
  test_pass "only the one added afterwards ran"
else
  test_fail "the wrong set ran: $(tr '\n' ' ' <"$MIG_DIR/order.log")"
fi

echo "preflight with no migrations is success, not an error"
# Also the case that would catch preflight growing migrate.sh's old bug: this
# runs under `set -u`, where bash 3.2 treats an empty array expansion as an
# unbound variable. preflight globs in the `for` instead, so nullglob makes it a
# zero-iteration loop.
MIG_DIR=$(new_migrate_sandbox preflight-none)
run_preflight "$MIG_DIR"
assert_says "it returns success" "returned=0"
assert_exists "the state directory is still created" "$MIG_DIR/home/.local/state/omakma/migrations"

echo "preflight run twice changes nothing"
# install.sh's ERR trap tells people to re-run it, so this happens.
MIG_DIR=$(new_migrate_sandbox preflight-twice)
write_migration "$MIG_DIR" 1700000000_first.sh first
run_preflight "$MIG_DIR"
run_preflight "$MIG_DIR"
assert_says "it returns success again" "returned=0"
assert_exists "the marker is still there" "$MIG_DIR/home/.local/state/omakma/migrations/1700000000_first.sh"
run_migrate "$MIG_DIR"
assert_quiet "and the migration is still skipped" "Running migration"

echo "OMAKMA_STATE_HOME decides where preflight writes too"
MIG_DIR=$(new_migrate_sandbox preflight-state-home)
write_migration "$MIG_DIR" 1700000000_first.sh first
run_preflight "$MIG_DIR" "$MIG_DIR/elsewhere"
assert_says "it returns success" "returned=0"
assert_exists "the marker lands under it" "$MIG_DIR/elsewhere/migrations/1700000000_first.sh"
assert_gone "and not under HOME" "$MIG_DIR/home/.local/state/omakma/migrations/1700000000_first.sh"
