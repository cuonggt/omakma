if [ ! -d /Applications/Sublime\ Text.app ]; then
  cd /tmp
  wget -O sublime_text.zip 'https://download.sublimetext.com/sublime_text_build_4180_mac.zip'
  unzip sublime_text.zip
  sudo mv Sublime\ Text.app /Applications
  rm sublime_text.zip
  cd -
fi

sudo ln -fs /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl

if [ ! -f $HOME/Library/Application\ Support/Sublime\ Text/Installed\ Packages/Package\ Control.sublime-package ]; then
  cd /tmp
  wget -O package_control.sublime-package https://packagecontrol.io/Package%20Control.sublime-package
  mv package_control.sublime-package $HOME/Library/Application\ Support/Sublime\ Text/Installed\ Packages/Package\ Control.sublime-package
  cd -
fi

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/Github\ Theme ]; then
  cd /tmp
  wget -O github-sublime-theme-4070-2.6.0.tar.gz https://github.com/mauroreisvieira/github-sublime-theme/archive/refs/tags/4070-2.6.0.tar.gz
  tar -xzf github-sublime-theme-4070-2.6.0.tar.gz
  mv github-sublime-theme-4070-2.6.0 $HOME/Library/Application\ Support/Sublime\ Text/Packages/Github\ Theme
  rm github-sublime-theme-4070-2.6.0.tar.gz
  cd -
fi

if [ ! -f $HOME/Library/Application\ Support/Sublime\ Text/Installed\ Packages/Inspired\ GitHub\ Color\ Scheme.sublime-package ]; then
  cd /tmp
  wget -O Inspired\ GitHub\ Color\ Scheme.sublime-package https://github.com/sethlopezme/InspiredGitHub.tmtheme/archive/refs/tags/v1.3.1.zip
  mv Inspired\ GitHub\ Color\ Scheme.sublime-package $HOME/Library/Application\ Support/Sublime\ Text/Installed\ Packages/Inspired\ GitHub\ Color\ Scheme.sublime-package
  cd -
fi

if [ ! -f $HOME/Library/Application\ Support/Sublime\ Text/Installed\ Packages/A\ File\ Icon.sublime-package ]; then
  cd /tmp
  wget -O A\ File\ Icon.sublime-package https://github.com/SublimeText/AFileIcon/releases/download/3.28.0/A.File.Icon.sublime-package
  mv A\ File\ Icon.sublime-package $HOME/Library/Application\ Support/Sublime\ Text/Installed\ Packages/A\ File\ Icon.sublime-package
  cd -
fi

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/AdvancedNewFile ]; then
  cd /tmp
  git clone https://github.com/SublimeText/AdvancedNewFile
  mv AdvancedNewFile $HOME/Library/Application\ Support/Sublime\ Text/Packages/AdvancedNewFile
  cd -
fi

mkdir -p $HOME/Library/Application\ Support/Sublime\ Text/Packages/User
cp $HOME/.local/share/omakma/configs/sublime/minimap_setting.py $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/minimap_setting.py
[ -f "$HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings" ] && mv $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings.bak
cp $HOME/.local/share/omakma/configs/sublime/Preferences.sublime-settings $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
