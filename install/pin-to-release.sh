# Choose which version of Omakma to install, in the clone at $1.
#
# The default is the most recent release rather than whatever master happens to
# be in the middle of. `master` stays checked out and tracking `origin/master`,
# only moved back to the tag, so `omakma update` fast-forwards to the tip -- a
# detached HEAD would leave `git pull` with nothing to follow, and a fix would
# never reach the machine. So installs are pinned and updates are not.
#
# $OMAKMA_REF overrides all of it: a tag, a branch, or "master" for the tip.

OMAKMA_CLONE="${1:-$HOME/.local/share/omakma}"

if [ -n "$OMAKMA_REF" ]; then
  # Taken at its word. A branch keeps tracking itself, so `omakma update`
  # follows whatever was asked for.
  if [ "$OMAKMA_REF" != "master" ]; then
    git -C "$OMAKMA_CLONE" fetch origin "$OMAKMA_REF" &&
      git -C "$OMAKMA_CLONE" checkout "$OMAKMA_REF"
  fi

  return 0 2>/dev/null || exit 0
fi

OMAKMA_RELEASE=$(git -C "$OMAKMA_CLONE" describe --tags --abbrev=0 origin/master 2>/dev/null)

if [ -z "$OMAKMA_RELEASE" ]; then
  echo "No release tag found. Installing from master."

  return 0 2>/dev/null || exit 0
fi

echo "Installing Omakma $OMAKMA_RELEASE. Updates will track master."
git -C "$OMAKMA_CLONE" reset --quiet --hard "$OMAKMA_RELEASE"
