app_uninstall sublime-text

SUBLIME_SUPPORT="$HOME/Library/Application Support/Sublime Text"

# Both settings files went in through copy_config, so whatever the user had is
# in .bak and can be handed back. `omakma theme` and `omakma font` rewrite lines
# inside Preferences.sublime-settings in place, so once either has run it reads
# here as a user edit and stays.
remove_installed_config "$SUBLIME_SUPPORT/Packages/User/Preferences.sublime-settings" \
  "$OMAKMA_PATH/configs/sublime/Preferences.sublime-settings"
restore_config_backup "$SUBLIME_SUPPORT/Packages/User/Preferences.sublime-settings"

remove_installed_config "$SUBLIME_SUPPORT/Packages/User/LSP.sublime-settings" \
  "$OMAKMA_PATH/configs/sublime/LSP.sublime-settings"
restore_config_backup "$SUBLIME_SUPPORT/Packages/User/LSP.sublime-settings"

remove_installed_config "$SUBLIME_SUPPORT/Packages/User/minimap_setting.py" \
  "$OMAKMA_PATH/configs/sublime/minimap_setting.py"

# The packages the installer clones.
remove_installed_clone "$SUBLIME_SUPPORT/Packages/Github Theme" "https://github.com/mauroreisvieira/github-sublime-theme.git"
remove_installed_clone "$SUBLIME_SUPPORT/Packages/Inspired GitHub Color Scheme" "https://github.com/sethlopezme/InspiredGitHub.tmtheme.git"
remove_installed_clone "$SUBLIME_SUPPORT/Packages/AFileIcon" "https://github.com/SublimeText/AFileIcon.git"
remove_installed_clone "$SUBLIME_SUPPORT/Packages/AdvancedNewFile" "https://github.com/SublimeText/AdvancedNewFile.git"
remove_installed_clone "$SUBLIME_SUPPORT/Packages/LSP" "https://github.com/sublimelsp/LSP.git"
remove_installed_clone "$SUBLIME_SUPPORT/Packages/LSP-json" "https://github.com/sublimelsp/LSP-json.git"
remove_installed_clone "$SUBLIME_SUPPORT/Packages/LSP-intelephense" "https://github.com/sublimelsp/LSP-intelephense.git"

# `omakma theme` clones a colour scheme package of its own for most themes. The
# names and repositories are read out of the theme files so this cannot drift
# from set-sublime-theme.sh.
for SUBLIME_THEME_FILE in "$OMAKMA_PATH"/themes/*/sublime.sh; do
  SUBLIME_THEME_PACKAGE=$(sed -n 's/^SUBLIME_PACKAGE_NAME="\(.*\)"$/\1/p' "$SUBLIME_THEME_FILE")
  SUBLIME_THEME_REPO=$(sed -n 's/^SUBLIME_PACKAGE_GITHUB="\(.*\)"$/\1/p' "$SUBLIME_THEME_FILE")

  if [ -n "$SUBLIME_THEME_PACKAGE" ] && [ -n "$SUBLIME_THEME_REPO" ]; then
    remove_installed_clone "$SUBLIME_SUPPORT/Packages/$SUBLIME_THEME_PACKAGE" \
      "https://github.com/$SUBLIME_THEME_REPO.git"
  fi
done

# Package Control is downloaded from packagecontrol.io and updates itself, so
# there is no way to tell Omakma's copy from one the user installed. Left alone.

remove_empty_dir "$SUBLIME_SUPPORT/Packages/User" "$SUBLIME_SUPPORT/Packages" \
  "$SUBLIME_SUPPORT/Installed Packages" "$SUBLIME_SUPPORT"
