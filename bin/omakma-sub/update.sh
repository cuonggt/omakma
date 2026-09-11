echo "Updating Omakma..."

if ! git -C "$OMAKMA_PATH" pull --rebase; then
  echo "Omakma update failed. Please check your network connection and try again."
  return 1 2>/dev/null || exit 1
fi

# migrate.sh returns non-zero as soon as a migration fails, so the update must
# not claim success without checking it.
if ! source "$OMAKMA_PATH/bin/omakma-sub/migrate.sh"; then
  echo "Omakma was updated, but a migration failed. Fix the problem above and re-run: omakma update"
  return 1 2>/dev/null || exit 1
fi

echo "Omakma updated successfully!"
