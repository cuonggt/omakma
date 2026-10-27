echo "Updating Omakma..."

# Every git failure here used to print the same "check your network", which for
# a checkout the user had edited, or one carrying a local commit, sent them to
# their router over the one thing only they could fix. Worse, a rebase that
# stopped part-way was left where it stopped: the checkout ends up detached with
# unmerged files, "try again" then fails forever, and that is precisely the
# state install/pin-to-release.sh exists to avoid -- a detached HEAD leaves
# `git pull` with nothing to follow, so no fix ever reaches the machine again.
# An update that strands a machine is worse than one that fails.
#
# So each way this can fail is identified before the network is touched, named
# for what it is, and given the command that clears it.
if [ -d "$OMAKMA_PATH/.git/rebase-merge" ] || [ -d "$OMAKMA_PATH/.git/rebase-apply" ]; then
  echo "Omakma's own checkout is part-way through a rebase, left behind by an update that stopped."
  echo "Undo it, then update again:"
  echo "  git -C \"$OMAKMA_PATH\" rebase --abort && omakma update"
  return 1 2>/dev/null || exit 1
fi

if ! git -C "$OMAKMA_PATH" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
  echo "Omakma's own checkout is on a detached HEAD, so there is no branch for the update to follow."
  echo "Put it back on master, then update again:"
  echo "  git -C \"$OMAKMA_PATH\" checkout master && omakma update"
  return 1 2>/dev/null || exit 1
fi

if ! git -C "$OMAKMA_PATH" rev-parse --verify --quiet "@{upstream}" >/dev/null 2>&1; then
  echo "Omakma's own checkout is on a branch that tracks nothing, so there is nowhere to update from."
  echo "Point it at master, then update again:"
  echo "  git -C \"$OMAKMA_PATH\" branch --set-upstream-to=origin/master && omakma update"
  return 1 2>/dev/null || exit 1
fi

if ! git -C "$OMAKMA_PATH" diff --quiet HEAD; then
  echo "Omakma's own checkout has local changes, so an update would not apply on top of them."
  echo "Keep them:  git -C \"$OMAKMA_PATH\" stash"
  echo "Drop them:  git -C \"$OMAKMA_PATH\" checkout ."
  echo "Then: omakma update"
  return 1 2>/dev/null || exit 1
fi

# Fetched and rebased in two steps rather than one `git pull --rebase`, so being
# offline and having diverged are told apart instead of sharing one message.
if ! git -C "$OMAKMA_PATH" fetch --quiet; then
  echo "Could not reach the Omakma repository. Please check your network connection and try again."
  return 1 2>/dev/null || exit 1
fi

# git's own report is left on screen rather than quietened: it names the commit
# or the file involved, which nothing written here could.
if ! git -C "$OMAKMA_PATH" rebase "@{upstream}"; then
  git -C "$OMAKMA_PATH" rebase --abort 2>/dev/null
  echo ""
  echo "The update would not apply on top of what is in Omakma's checkout, so it was undone and the checkout left exactly as it was."
  echo "Sort out what git reported above, then: omakma update"
  return 1 2>/dev/null || exit 1
fi

# migrate.sh returns non-zero as soon as a migration fails, so the update must
# not claim success without checking it.
if ! source "$OMAKMA_PATH/bin/omakma-sub/migrate.sh"; then
  echo "Omakma was updated, but a migration failed. Fix the problem above and re-run: omakma update"
  return 1 2>/dev/null || exit 1
fi

echo "Omakma updated successfully!"
