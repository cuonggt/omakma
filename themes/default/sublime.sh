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

gsed -i "s/\"light_theme\": \".*\"/\"light_theme\": \"GitHub Light.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"dark_theme\": \".*\"/\"dark_theme\": \"GitHub Dark.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"color_scheme\": \".*\"/\"color_scheme\": \"Packages\/Inspired GitHub Color Scheme\/InspiredGitHub.tmtheme-1.3.1\/InspiredGitHub.tmTheme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
