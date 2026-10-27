if command -v code &>/dev/null; then
  # The themes the edit below names come from this extension, so writing them
  # when it did not install leaves VS Code set to a theme it does not have.
  # Unguarded, this wrote them anyway: `code` reported its own failure and the
  # theme was switched to something that was never there.
  if ! code --install-extension "$VSC_EXTENSION" >/dev/null; then
    setup_failed "the $VSC_EXTENSION extension"
    echo "VS Code's theme was left as it was."
    return 0 2>/dev/null || exit 0
  fi

  edit_config "$HOME/Library/Application Support/Code/User/settings.json" \
    "s/\"workbench.colorTheme\": \".*\"/\"workbench.colorTheme\": \"$VSC_LIGHT_THEME\"/g" \
    "s/\"workbench.preferredLightColorTheme\": \".*\"/\"workbench.preferredLightColorTheme\": \"$VSC_LIGHT_THEME\"/g" \
    "s/\"workbench.preferredDarkColorTheme\": \".*\"/\"workbench.preferredDarkColorTheme\": \"$VSC_DARK_THEME\"/g"
fi
