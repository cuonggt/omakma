# What `omakma update` does when the pull does not go through.
#
# Every git failure used to print "check your network", which for a checkout the
# user had edited, or one carrying a local commit, sent them to their router over
# the one thing only they could fix. And a rebase that stopped part-way was left
# where it stopped: the checkout ends up detached with unmerged files, "try
# again" fails forever after that, and a detached HEAD is the single state
# install/pin-to-release.sh exists to avoid -- `git pull` has nothing to follow,
# so no fix ever reaches the machine again. An update that strands a machine is
# worse than one that fails.
#
# These cases run the real sub-command against a throwaway remote built from
# scratch. No network: the remote is a path on disk.

# make_update_remote <dir>
# A throwaway remote one commit ahead of a clone of it, so there is a real
# update to take. Built from scratch rather than from this repository, because
# on CI there is nothing to borrow -- actions/checkout leaves a shallow detached
# HEAD with no master branch.
make_update_remote() {
  local dir="$1"
  local git_as="git -c user.email=test@example.com -c user.name=test"

  git init --quiet "$dir/work"
  # Set on the unborn branch, so init.defaultBranch does not matter.
  git -C "$dir/work" symbolic-ref HEAD refs/heads/master

  mkdir -p "$dir/work/bin/omakma-sub"
  # Stands in for the migration runner, which update.sh sources out of the
  # checkout it has just updated. What migrations do is migrate.sh's business.
  echo ': # no migrations to run' >"$dir/work/bin/omakma-sub/migrate.sh"
  echo "0.1.0" >"$dir/work/version"
  git -C "$dir/work" add .
  $git_as -C "$dir/work" commit --quiet -m "the release"

  git clone --quiet --bare "$dir/work" "$dir/remote.git"
  # Without this the bare clone inherits whatever branch happened to be checked
  # out as its HEAD, and the clone below lands somewhere other than master.
  git -C "$dir/remote.git" symbolic-ref HEAD refs/heads/master

  # Cloned now, so it is behind the commit that follows.
  git clone --quiet "$dir/remote.git" "$dir/install"
  git -C "$dir/install" config user.email test@example.com
  git -C "$dir/install" config user.name test

  echo "0.1.1" >"$dir/work/version"
  git -C "$dir/work" add version
  $git_as -C "$dir/work" commit --quiet -m "a newer release"
  git -C "$dir/work" push --quiet "$dir/remote.git" master

  mkdir -p "$dir/home"
}

# new_update_sandbox <name>
# A throwaway remote and a clone of it, under the test sandbox.
new_update_sandbox() {
  local dir="$TEST_SANDBOX/$1"

  mkdir -p "$dir"
  make_update_remote "$dir"
  printf '%s' "$dir"
}

# run_update <dir>
# Source the real sub-command with OMAKMA_PATH pointed at the throwaway clone.
# `return N` inside a sourced file ends that file rather than this subshell, so
# the status is still there to report.
run_update() {
  RUN_DIR="$1"
  RUN_CHECKOUT="$OMAKMA_PATH"

  TEST_OUTPUT=$(
    exec 2>&1
    set --
    OMAKMA_PATH="$RUN_DIR/install"
    export OMAKMA_PATH
    HOME="$RUN_DIR/home"
    export HOME
    # Branched on rather than read from `$?`: the sub-command ends in an echo
    # on its success path, so `$?` after it describes that echo as much as the
    # script, and `$?` read inline has twice meant the wrong command in this
    # repository's history. Success or failure is all these cases ask.
    if source "$RUN_CHECKOUT/bin/omakma-sub/update.sh"; then
      echo "returned=0"
    else
      echo "returned=1"
    fi
  )
}

# assert_on_branch <dir>
# The assertion the whole change exists for: whatever went wrong, the checkout
# is still on a branch and has no rebase half-done, so the next update can move.
assert_on_branch() {
  if git -C "$1/install" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
    test_pass "the checkout is still on a branch, so a later fix can still arrive"
  else
    test_fail "the checkout was left detached, which no update can recover from"
  fi

  assert_gone "and no rebase is left half-done" "$1/install/.git/rebase-merge"
}

echo "an update that applies cleanly takes the newer release"
UPDATE_DIR=$(new_update_sandbox update-clean)
run_update "$UPDATE_DIR"
assert_says "it reports success" "Omakma updated successfully!"
assert_says "and returns success" "returned=0"
if [ "$(cat "$UPDATE_DIR/install/version")" = "0.1.1" ]; then
  test_pass "the newer release is checked out"
else
  test_fail "the checkout is still at $(cat "$UPDATE_DIR/install/version")"
fi
assert_on_branch "$UPDATE_DIR"

echo "a checkout the user has edited is named rather than blamed on the network"
UPDATE_DIR=$(new_update_sandbox update-dirty)
echo "edited by hand" >>"$UPDATE_DIR/install/version"
run_update "$UPDATE_DIR"
assert_says "it says what is actually wrong" "has local changes"
assert_says "it offers to keep them" "Keep them:"
assert_says "and to drop them" "Drop them:"
assert_quiet "it does not send the user to their router" "network connection"
assert_says "and it stops" "returned=1"
# Read from the file rather than the output: what matters is that the edit
# survived on disk, which nothing the script printed could show.
if grep -q "edited by hand" "$UPDATE_DIR/install/version"; then
  test_pass "the edit is left alone"
else
  test_fail "the user's own edit was discarded"
fi
assert_on_branch "$UPDATE_DIR"

echo "a detached checkout is named, since there is no branch to follow"
UPDATE_DIR=$(new_update_sandbox update-detached)
git -C "$UPDATE_DIR/install" checkout --quiet --detach
run_update "$UPDATE_DIR"
assert_says "it says what is wrong" "detached HEAD"
assert_says "and names the command that fixes it" "checkout master"
assert_quiet "rather than blaming the network" "network connection"
assert_says "and it stops" "returned=1"

echo "a branch that tracks nothing is named, since there is nowhere to update from"
UPDATE_DIR=$(new_update_sandbox update-no-upstream)
git -C "$UPDATE_DIR/install" branch --unset-upstream
run_update "$UPDATE_DIR"
assert_says "it says what is wrong" "tracks nothing"
assert_says "and names the command that fixes it" "set-upstream-to"
assert_quiet "rather than blaming the network" "network connection"
assert_says "and it stops" "returned=1"

echo "a rebase left half-done by an earlier attempt is named, not pulled over"
UPDATE_DIR=$(new_update_sandbox update-mid-rebase)
echo "conflicting" >"$UPDATE_DIR/install/version"
git -C "$UPDATE_DIR/install" commit --quiet -am "a conflicting local commit"
# Wedged for real, by the rebase the old update.sh would have run.
git -C "$UPDATE_DIR/install" fetch --quiet
git -C "$UPDATE_DIR/install" rebase "@{upstream}" >/dev/null 2>&1
assert_exists "the rebase really is half-done" "$UPDATE_DIR/install/.git/rebase-merge"
run_update "$UPDATE_DIR"
assert_says "it says what is wrong" "part-way through a rebase"
assert_says "and names the command that clears it" "rebase --abort"
assert_quiet "rather than blaming the network" "network connection"
assert_says "and it stops" "returned=1"

echo "a local commit that will not rebase is undone rather than left stranded"
UPDATE_DIR=$(new_update_sandbox update-conflict)
echo "conflicting" >"$UPDATE_DIR/install/version"
git -C "$UPDATE_DIR/install" commit --quiet -am "a conflicting local commit"
LOCAL_COMMIT=$(git -C "$UPDATE_DIR/install" rev-parse HEAD)
run_update "$UPDATE_DIR"
assert_says "it says the update was undone" "left exactly as it was"
assert_quiet "rather than blaming the network" "network connection"
assert_says "and it stops" "returned=1"
assert_on_branch "$UPDATE_DIR"
if [ "$(git -C "$UPDATE_DIR/install" rev-parse HEAD)" = "$LOCAL_COMMIT" ]; then
  test_pass "the user's own commit is still there"
else
  test_fail "HEAD no longer points at the user's own commit"
fi

echo "an unreachable remote is the one case the network message belongs to"
UPDATE_DIR=$(new_update_sandbox update-offline)
git -C "$UPDATE_DIR/install" remote set-url origin "$UPDATE_DIR/gone.git"
run_update "$UPDATE_DIR"
assert_says "it names the network" "check your network connection"
assert_says "and it stops" "returned=1"
assert_on_branch "$UPDATE_DIR"
