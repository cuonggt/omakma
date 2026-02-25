# Ensure computer doesn't go to sleep while installing
caffeinate -dims &
CAFFEINATE_PID=$!

# Run desktop installers
for installer in "$OMAKMA_PATH"/install/desktop/*.sh; do source "$installer"; done

# Revert to normal idle settings
kill $CAFFEINATE_PID 2>/dev/null

# Reboot to pick up changes
if gum confirm "Ready to reboot for all settings to take effect?"; then
  sudo shutdown -r now
else
  echo "Skipping reboot. Please reboot manually for all settings to take effect."
fi
