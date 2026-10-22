if command -v code &>/dev/null; then
  code --install-extension "$VSC_EXTENSION" >/dev/null

  edit_config "$HOME/Library/Application Support/Code/User/settings.json" \
    "s/\"workbench.colorTheme\": \".*\"/\"workbench.colorTheme\": \"$VSC_LIGHT_THEME\"/g" \
    "s/\"workbench.preferredLightColorTheme\": \".*\"/\"workbench.preferredLightColorTheme\": \"$VSC_LIGHT_THEME\"/g" \
    "s/\"workbench.preferredDarkColorTheme\": \".*\"/\"workbench.preferredDarkColorTheme\": \"$VSC_DARK_THEME\"/g"
fi
