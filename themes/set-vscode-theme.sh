code --install-extension $VSC_EXTENSION >/dev/null

gsed -i "s/\"workbench.colorTheme\": \".*\"/\"workbench.colorTheme\": \"$VSC_LIGHT_THEME\"/g" $HOME/Library/Application\ Support/Code/User/settings.json
gsed -i "s/\"workbench.preferredLightColorTheme\": \".*\"/\"workbench.preferredLightColorTheme\": \"$VSC_LIGHT_THEME\"/g" $HOME/Library/Application\ Support/Code/User/settings.json
gsed -i "s/\"workbench.preferredDarkColorTheme\": \".*\"/\"workbench.preferredDarkColorTheme\": \"$VSC_DARK_THEME\"/g" $HOME/Library/Application\ Support/Code/User/settings.json
