# Which version boot.sh installs, and whether `omakma update` can still move.
#
# The failure that matters here is silent: pinning the install by checking out a
# tag directly leaves a detached HEAD, `git pull` then has nothing to follow,
# and no fix ever reaches the machine again. So boot.sh's choice of ref lives in
# install/pin-to-release.sh, which these cases source for real against a
# throwaway remote built from this repository. No network.

# make_boot_remote <dir> <with-tags: yes|no>
# A throwaway repository with its own history: a release commit, a tag on it,
# and one commit after, so master is ahead of the newest release.
#
# Built from scratch rather than cloned from this repository. On CI there is
# nothing to borrow -- actions/checkout leaves a shallow detached HEAD with no
# master branch and no tags, so a bare clone of it has no master for the remote
# HEAD to point at and `git describe` has nothing to find.
make_boot_remote() {
  local dir="$1"
  local with_tags="$2"
  local git_as="git -c user.email=test@example.com -c user.name=test"

  git init --quiet "$dir/work"
  # Set on the unborn branch, so it does not matter what init.defaultBranch is.
  git -C "$dir/work" symbolic-ref HEAD refs/heads/master

  echo "0.1.0" >"$dir/work/version"
  git -C "$dir/work" add version
  $git_as -C "$dir/work" commit --quiet -m "the release"

  if [ "$with_tags" = yes ]; then
    $git_as -C "$dir/work" tag -a v0.1.0 -m "v0.1.0"
  fi

  echo "after the release" >"$dir/work/POST_RELEASE.md"
  git -C "$dir/work" add POST_RELEASE.md
  $git_as -C "$dir/work" commit --quiet -m "a commit after the release"

  git clone --quiet --bare "$dir/work" "$dir/remote.git"
  git -C "$dir/remote.git" symbolic-ref HEAD refs/heads/master
}

# pin_clone <dir> <ref-or-empty>
# Clone the throwaway remote and run the real ref selection over it.
pin_clone() {
  git clone --quiet "$1/remote.git" "$1/install"

  TEST_OUTPUT=$(
    exec 2>&1
    OMAKMA_REF="$2"
    export OMAKMA_REF
    source "$OMAKMA_PATH/install/pin-to-release.sh" "$1/install"
  )
}

echo "by default the install is pinned to the most recent release"
BOOT_DIR="$TEST_SANDBOX/boot-default"
mkdir -p "$BOOT_DIR"
make_boot_remote "$BOOT_DIR" yes
RELEASE_COMMIT=$(git -C "$BOOT_DIR/work" rev-list -n1 v0.1.0)
MASTER_TIP=$(git -C "$BOOT_DIR/work" rev-parse master)

pin_clone "$BOOT_DIR" ""
assert_says "it names the release it is installing" "Updates will track master"
if [ "$(git -C "$BOOT_DIR/install" rev-parse HEAD)" = "$RELEASE_COMMIT" ]; then
  test_pass "the clone is moved back to the release commit"
else
  test_fail "the clone is not at the release commit"
fi
assert_gone "so a change made after the release is not installed" "$BOOT_DIR/install/POST_RELEASE.md"

echo "and master is still checked out and tracking, so updates can move"
if git -C "$BOOT_DIR/install" symbolic-ref -q HEAD >/dev/null; then
  test_pass "HEAD is not detached"
else
  test_fail "HEAD is detached, which would stop omakma update dead"
fi
if [ "$(git -C "$BOOT_DIR/install" rev-parse --abbrev-ref HEAD)" = master ]; then
  test_pass "the branch is master"
else
  test_fail "the branch is not master"
fi
if [ "$(git -C "$BOOT_DIR/install" rev-parse --abbrev-ref '@{u}' 2>/dev/null)" = origin/master ]; then
  test_pass "tracking origin/master"
else
  test_fail "upstream is not origin/master"
fi

echo "omakma update then fast-forwards to the tip"
git -C "$BOOT_DIR/install" pull --rebase --quiet >/dev/null 2>&1
if [ "$(git -C "$BOOT_DIR/install" rev-parse HEAD)" = "$MASTER_TIP" ]; then
  test_pass "the update reaches master"
else
  test_fail "the update did not reach master"
fi
assert_exists "and the post-release change arrives" "$BOOT_DIR/install/POST_RELEASE.md"

echo "OMAKMA_REF=master installs the tip instead"
BOOT_DIR="$TEST_SANDBOX/boot-master"
mkdir -p "$BOOT_DIR"
make_boot_remote "$BOOT_DIR" yes
MASTER_TIP=$(git -C "$BOOT_DIR/work" rev-parse master)
pin_clone "$BOOT_DIR" master
if [ "$(git -C "$BOOT_DIR/install" rev-parse HEAD)" = "$MASTER_TIP" ]; then
  test_pass "the clone is left at the tip"
else
  test_fail "asking for master did not give master"
fi
assert_exists "including the post-release change" "$BOOT_DIR/install/POST_RELEASE.md"

echo "a repository with no releases yet installs master"
BOOT_DIR="$TEST_SANDBOX/boot-untagged"
mkdir -p "$BOOT_DIR"
make_boot_remote "$BOOT_DIR" no
MASTER_TIP=$(git -C "$BOOT_DIR/work" rev-parse master)
pin_clone "$BOOT_DIR" ""
assert_says "it says why it is not pinning" "No release tag found"
if [ "$(git -C "$BOOT_DIR/install" rev-parse HEAD)" = "$MASTER_TIP" ]; then
  test_pass "and installs the tip rather than failing"
else
  test_fail "an untagged repository was left somewhere unexpected"
fi

echo "boot.sh itself delegates the choice rather than detaching"
BOOT_CONTENT=$(cat "$OMAKMA_PATH/boot.sh")
case "$BOOT_CONTENT" in
*install/pin-to-release.sh*) test_pass "boot.sh sources the ref selection" ;;
*) test_fail "boot.sh no longer uses install/pin-to-release.sh" ;;
esac
case "$BOOT_CONTENT" in
*detach*) test_fail "boot.sh detaches HEAD, which would stop omakma update" ;;
*) test_pass "boot.sh does not detach HEAD" ;;
esac
