# Ensure computer doesn't go to sleep while installing
keep_awake

# Run desktop installers
for installer in "$OMAKMA_PATH"/install/desktop/*.sh; do source "$installer"; done

# Revert to normal idle settings
let_sleep

# Name anything Homebrew would not install, before the reboot prompt -- after it
# the user is gone.
report_failed_installs

# Reboot to pick up changes
if gum confirm "Ready to reboot for all settings to take effect?"; then
  sudo shutdown -r now
else
  echo "Skipping reboot. Please reboot manually for all settings to take effect."
fi
