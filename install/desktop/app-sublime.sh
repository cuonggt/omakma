app_install sublime-text "Sublime Text.app"

SUBLIME_SUPPORT="$HOME/Library/Application Support/Sublime Text"

mkdir -p "$SUBLIME_SUPPORT/Installed Packages"
mkdir -p "$SUBLIME_SUPPORT/Packages/User"

if [ ! -f "$SUBLIME_SUPPORT/Installed Packages/Package Control.sublime-package" ]; then
  if wget -q -O /tmp/package_control.sublime-package https://packagecontrol.io/Package%20Control.sublime-package; then
    mv /tmp/package_control.sublime-package "$SUBLIME_SUPPORT/Installed Packages/Package Control.sublime-package"
  else
    download_failed "Package Control"
  fi
fi

clone_if_missing "$SUBLIME_SUPPORT/Packages/Github Theme" https://github.com/mauroreisvieira/github-sublime-theme.git

clone_if_missing "$SUBLIME_SUPPORT/Packages/Inspired GitHub Color Scheme" https://github.com/sethlopezme/InspiredGitHub.tmtheme.git

clone_if_missing "$SUBLIME_SUPPORT/Packages/AFileIcon" https://github.com/SublimeText/AFileIcon.git

clone_if_missing "$SUBLIME_SUPPORT/Packages/AdvancedNewFile" https://github.com/SublimeText/AdvancedNewFile.git

cp "$OMAKMA_PATH/configs/sublime/minimap_setting.py" "$SUBLIME_SUPPORT/Packages/User/minimap_setting.py"
copy_config "$OMAKMA_PATH/configs/sublime/Preferences.sublime-settings" "$SUBLIME_SUPPORT/Packages/User/Preferences.sublime-settings"

clone_if_missing "$SUBLIME_SUPPORT/Packages/LSP" https://github.com/sublimelsp/LSP.git

clone_if_missing "$SUBLIME_SUPPORT/Packages/LSP-json" https://github.com/sublimelsp/LSP-json.git

clone_if_missing "$SUBLIME_SUPPORT/Packages/LSP-intelephense" https://github.com/sublimelsp/LSP-intelephense.git

copy_config "$OMAKMA_PATH/configs/sublime/LSP.sublime-settings" "$SUBLIME_SUPPORT/Packages/User/LSP.sublime-settings"
