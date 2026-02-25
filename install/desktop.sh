# Ensure computer doesn't go to sleep while installing
caffeinate -dims &
CAFFEINATE_PID=$!

# Run desktop installers
for installer in $HOME/.local/share/omakma/install/desktop/*.sh; do source $installer; done

# Revert to normal idle settings
kill $CAFFEINATE_PID 2>/dev/null

# Logout to pickup changes
gum confirm "Ready to reboot for all settings to take effect?" && sudo shutdown -r now
