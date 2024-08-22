if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/Everforest ]; then
  git clone https://github.com/avelican/everforest-sublime.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/Everforest
fi

gsed -i "s/\"color_scheme\": \".*\"/\"color_scheme\": \"Everforest Light.sublime-color-scheme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"light_theme\": \".*\"/\"light_theme\": \"Everforest Light.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"dark_theme\": \".*\"/\"dark_theme\": \"Everforest Dark.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
