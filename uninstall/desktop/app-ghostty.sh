app_uninstall ghostty

# `omakma theme`, `omakma font` and the font-size menu each rewrite a line
# inside config in place rather than recopying it, so once any of them has run
# the file reads here as a user edit and stays. That is the right side to err on
# for the one file in this directory a Ghostty user is likely to have written.
remove_installed_config "$HOME/.config/ghostty/config" \
  "$OMAKMA_PATH/configs/ghostty/config"

restore_config_backup "$HOME/.config/ghostty/config"

for GHOSTTY_THEME in "$OMAKMA_PATH"/configs/ghostty/themes/*; do
  THEME_FILE="$HOME/.config/ghostty/themes/$(basename "$GHOSTTY_THEME")"
  remove_installed_config "$THEME_FILE" "$GHOSTTY_THEME"
  restore_config_backup "$THEME_FILE"
done

remove_empty_dir "$HOME/.config/ghostty/themes" "$HOME/.config/ghostty"
