if [ ! -d /Applications/Sublime\ Text.app ]; then
  brew install --cask sublime-text
fi

mkdir -p $HOME/Library/Application\ Support/Sublime\ Text/Installed\ Packages
mkdir -p $HOME/Library/Application\ Support/Sublime\ Text/Packages/User

if [ ! -f $HOME/Library/Application\ Support/Sublime\ Text/Installed\ Packages/Package\ Control.sublime-package ]; then
  cd /tmp
  wget -O package_control.sublime-package https://packagecontrol.io/Package%20Control.sublime-package
  mv package_control.sublime-package $HOME/Library/Application\ Support/Sublime\ Text/Installed\ Packages/Package\ Control.sublime-package
  cd -
fi

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/Github\ Theme ]; then
  git clone https://github.com/mauroreisvieira/github-sublime-theme.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/Github\ Theme
fi

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/Inspired\ GitHub\ Color\ Scheme ]; then
  git clone https://github.com/sethlopezme/InspiredGitHub.tmtheme.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/Inspired\ GitHub\ Color\ Scheme
fi

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/AFileIcon ]; then
  git clone https://github.com/SublimeText/AFileIcon.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/AFileIcon
fi

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/AdvancedNewFile ]; then
  git clone https://github.com/SublimeText/AdvancedNewFile.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/AdvancedNewFile
fi

cp $HOME/.local/share/omakma/configs/sublime/minimap_setting.py $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/minimap_setting.py
[ -f "$HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings" ] && mv $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings.bak
cp $HOME/.local/share/omakma/configs/sublime/Preferences.sublime-settings $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/LSP ]; then
  git clone https://github.com/sublimelsp/LSP.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/LSP
fi

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/LSP-json ]; then
  git clone https://github.com/sublimelsp/LSP-json.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/LSP-json
fi

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/LSP-intelephense ]; then
  git clone https://github.com/sublimelsp/LSP-intelephense.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/LSP-intelephense
fi

[ -f "$HOME/Library/Application\ Support/Sublime\ Text/Packages/User/LSP.sublime-settings" ] && mv $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/LSP.sublime-settings $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/LSP.sublime-settings.bak
cp $HOME/.local/share/omakma/configs/sublime/LSP.sublime-settings $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/LSP.sublime-settings
# [ -f "$HOME/Library/Application\ Support/Sublime\ Text/Packages/User/LSP-json.sublime-settings" ] && mv $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/LSP-json.sublime-settings $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/LSP-json.sublime-settings.bak
# cp $HOME/.local/share/omakma/configs/sublime/LSP-json.sublime-settings $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/LSP-json.sublime-settings
