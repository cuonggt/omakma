if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/Theme\ -\ Rose\ Pine ]; then
  cd /tmp
  wget -O sublime-text-0.1.2.tar.gz https://codeload.github.com/rose-pine/sublime-text/tar.gz/refs/tags/0.1.2
  tar -xzf sublime-text-0.1.2.tar.gz
  mv sublime-text-0.1.2 $HOME/Library/Application\ Support/Sublime\ Text/Packages/Theme\ -\ Rose\ Pine
  rm sublime-text-0.1.2.tar.gz
  cd -
fi

gsed -i "s/\"light_theme\": \".*\"/\"light_theme\": \"Rosé Pine Dawn.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"dark_theme\": \".*\"/\"dark_theme\": \"Rosé Pine.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"color_scheme\": \".*\"/\"color_scheme\": \"Rosé Pine Dawn.sublime-color-scheme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
