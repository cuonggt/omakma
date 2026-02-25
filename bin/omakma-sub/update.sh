echo "Updating Omakma..."

if git -C "$OMAKMA_PATH" pull --rebase; then
  echo "Omakma updated successfully!"
else
  echo "Omakma update failed. Please check your network connection and try again."
fi
