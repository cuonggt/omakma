brew_app_uninstall zellij

# `omakma theme` copies <theme>.kdl in beside the one the installer wrote, so
# clear every theme file that still matches the theme it came from.
for THEME_DIR in "$OMAKMA_PATH"/themes/*/; do
  remove_installed_config \
    "$HOME/.config/zellij/themes/$(basename "$THEME_DIR").kdl" \
    "${THEME_DIR%/}/zellij.kdl"
done

# config.kdl is written once, only when absent, and `omakma theme` then edits
# the theme line in place -- so a switched theme reads here as a user edit and
# the file stays. Three lines left behind is the right side to err on: this is
# the file zellij keeps the user's keybinds in, and zellij rewrites it itself.
remove_installed_config "$HOME/.config/zellij/config.kdl" \
  "$OMAKMA_PATH/configs/zellij.kdl"

remove_empty_dir "$HOME/.config/zellij/themes" "$HOME/.config/zellij"
