SUBLIME_PACKAGE_PATH=$HOME/Library/Application\ Support/Sublime\ Text/Packages/$SUBLIME_PACKAGE_NAME

[ -d "$SUBLIME_PACKAGE_PATH" ] || git clone https://github.com/$SUBLIME_PACKAGE_GITHUB.git "$SUBLIME_PACKAGE_PATH"

gsed -i "s/\"color_scheme\": \".*\"/\"color_scheme\": \"$SUBLIME_COLOR_SCHEME.sublime-color-scheme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"light_theme\": \".*\"/\"light_theme\": \"$SUBLIME_LIGHT_THEME.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"dark_theme\": \".*\"/\"dark_theme\": \"$SUBLIME_DARK_THEME.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
