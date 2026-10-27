# Which migrations run, in what order, and what a failing one does.
#
# bin/omakma-sub/migrate.sh decides what reaches a machine that is already
# installed: a fix made inside an installer only ever helps machines set up
# after it, so everything else goes through here. It had no coverage at all --
# test/update.sh stubs it out with a file in its throwaway remote, so the real
# runner was never exercised by anything. Blanking it left the suite green.
#
# The migrations here are written into a throwaway OMAKMA_PATH, so nothing in
# the repository's own migrations/ directory runs.

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
  RUN_CHECKOUT="$OMAKMA_PATH"

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
    if source "$RUN_CHECKOUT/bin/omakma-sub/migrate.sh"; then
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
