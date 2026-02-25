if [ ! -d /Applications/Sublime\ Text.app ]; then
  brew install --cask sublime-text
fi

SUBLIME_SUPPORT="$HOME/Library/Application Support/Sublime Text"

mkdir -p "$SUBLIME_SUPPORT/Installed Packages"
mkdir -p "$SUBLIME_SUPPORT/Packages/User"

if [ ! -f "$SUBLIME_SUPPORT/Installed Packages/Package Control.sublime-package" ]; then
  if wget -q -O /tmp/package_control.sublime-package https://packagecontrol.io/Package%20Control.sublime-package; then
    mv /tmp/package_control.sublime-package "$SUBLIME_SUPPORT/Installed Packages/Package Control.sublime-package"
  fi
fi

if [ ! -d "$SUBLIME_SUPPORT/Packages/Github Theme" ]; then
  git clone https://github.com/mauroreisvieira/github-sublime-theme.git "$SUBLIME_SUPPORT/Packages/Github Theme"
fi

if [ ! -d "$SUBLIME_SUPPORT/Packages/Inspired GitHub Color Scheme" ]; then
  git clone https://github.com/sethlopezme/InspiredGitHub.tmtheme.git "$SUBLIME_SUPPORT/Packages/Inspired GitHub Color Scheme"
fi

if [ ! -d "$SUBLIME_SUPPORT/Packages/AFileIcon" ]; then
  git clone https://github.com/SublimeText/AFileIcon.git "$SUBLIME_SUPPORT/Packages/AFileIcon"
fi

if [ ! -d "$SUBLIME_SUPPORT/Packages/AdvancedNewFile" ]; then
  git clone https://github.com/SublimeText/AdvancedNewFile.git "$SUBLIME_SUPPORT/Packages/AdvancedNewFile"
fi

cp "$OMAKMA_PATH/configs/sublime/minimap_setting.py" "$SUBLIME_SUPPORT/Packages/User/minimap_setting.py"
[ -f "$SUBLIME_SUPPORT/Packages/User/Preferences.sublime-settings" ] && mv "$SUBLIME_SUPPORT/Packages/User/Preferences.sublime-settings" "$SUBLIME_SUPPORT/Packages/User/Preferences.sublime-settings.bak"
cp "$OMAKMA_PATH/configs/sublime/Preferences.sublime-settings" "$SUBLIME_SUPPORT/Packages/User/Preferences.sublime-settings"

if [ ! -d "$SUBLIME_SUPPORT/Packages/LSP" ]; then
  git clone https://github.com/sublimelsp/LSP.git "$SUBLIME_SUPPORT/Packages/LSP"
fi

if [ ! -d "$SUBLIME_SUPPORT/Packages/LSP-json" ]; then
  git clone https://github.com/sublimelsp/LSP-json.git "$SUBLIME_SUPPORT/Packages/LSP-json"
fi

if [ ! -d "$SUBLIME_SUPPORT/Packages/LSP-intelephense" ]; then
  git clone https://github.com/sublimelsp/LSP-intelephense.git "$SUBLIME_SUPPORT/Packages/LSP-intelephense"
fi

[ -f "$SUBLIME_SUPPORT/Packages/User/LSP.sublime-settings" ] && mv "$SUBLIME_SUPPORT/Packages/User/LSP.sublime-settings" "$SUBLIME_SUPPORT/Packages/User/LSP.sublime-settings.bak"
cp "$OMAKMA_PATH/configs/sublime/LSP.sublime-settings" "$SUBLIME_SUPPORT/Packages/User/LSP.sublime-settings"
