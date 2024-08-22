if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/Theme\ -\ Rose\ Pine ]; then
  git clone https://github.com/rose-pine/sublime-text.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/Theme\ -\ Rose\ Pine
fi

gsed -i "s/\"color_scheme\": \".*\"/\"color_scheme\": \"Rosé Pine Dawn.sublime-color-scheme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"light_theme\": \".*\"/\"light_theme\": \"Rosé Pine Dawn.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"dark_theme\": \".*\"/\"dark_theme\": \"Rosé Pine.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
