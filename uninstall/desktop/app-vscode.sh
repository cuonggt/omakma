app_uninstall visual-studio-code || return 1 2>/dev/null || exit 1

# Only remove the symlink while it is still the one the installer made: it was
# created with `ln -fs`, so a `code` the user had pointing elsewhere was already
# clobbered once and should not be deleted on top of that. Checking first also
# avoids calling sudo at all when there is nothing to remove -- `sudo rm -f` on
# a path that is already gone still stops to ask for a password, which made
# re-running this ask for one to do nothing.
if [ "$(readlink /usr/local/bin/code 2>/dev/null)" = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
  sudo rm -f /usr/local/bin/code
fi

# `omakma theme` and `omakma font` rewrite lines inside settings.json in place,
# so once either has run the file reads here as a user edit and stays.
remove_installed_config "$HOME/Library/Application Support/Code/User/settings.json" \
  "$OMAKMA_PATH/configs/vscode.json"

restore_config_backup "$HOME/Library/Application Support/Code/User/settings.json"

# The extensions the installer added are left in ~/.vscode/extensions. They are
# the user's to keep, and `code` is gone by this point anyway.
