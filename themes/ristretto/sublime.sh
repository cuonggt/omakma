if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/Github\ Theme ]; then
  git clone https://github.com/mauroreisvieira/github-sublime-theme.git $HOME/Library/Application\ Support/Sublime\ Text/Packages/Github\ Theme
fi

if [ ! -d $HOME/Library/Application\ Support/Sublime\ Text/Packages/Inspired\ GitHub\ Color\ Scheme ]; then
  git clone https://github.com/sethlopezme/InspiredGitHub.tmtheme.git $HOME/Library/Application\ Support/Sublime\ Text/Inspired\ GitHub\ Color\ Scheme
fi

gsed -i "s/\"color_scheme\": \".*\"/\"color_scheme\": \"Packages\/Inspired GitHub Color Scheme\/InspiredGitHub.tmTheme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"light_theme\": \".*\"/\"light_theme\": \"GitHub Light.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
gsed -i "s/\"dark_theme\": \".*\"/\"dark_theme\": \"GitHub Dark.sublime-theme\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
