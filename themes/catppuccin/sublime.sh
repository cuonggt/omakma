if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/Catppuccin ]; then
  git clone https://github.com/catppuccin/sublime-text.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/Catppuccin
fi

gsed -i "s/\"color_scheme\": \".*\"/\"color_scheme\": \"Catppuccin Latte.sublime-color-scheme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"light_theme\": \".*\"/\"light_theme\": \"Default.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"dark_theme\": \".*\"/\"dark_theme\": \"Default Dark.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
