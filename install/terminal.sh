# Ensure computer doesn't go to sleep while installing
caffeinate -dims &
CAFFEINATE_PID=$!

# Run terminal installers
for installer in "$OMAKMA_PATH"/install/terminal/*.sh; do source "$installer"; done

# Revert to normal idle settings
kill $CAFFEINATE_PID 2>/dev/null
