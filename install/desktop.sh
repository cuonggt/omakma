# Ensure computer doesn't go to sleep or lock while installing
# caffeinate?

# Run desktop installers
for installer in $HOME/.local/share/omakma/install/desktop/*.sh; do source $installer; done

# Revert to normal idle and lock settings
# caffeinate?

# Logout to pickup changes
gum confirm "Ready to reboot for all settings to take effect?" && sudo shutdown -r now
