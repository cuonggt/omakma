brew_app_uninstall alacritty

remove_installed_config "$HOME/.config/alacritty/alacritty.toml" \
  "$OMAKMA_PATH/configs/alacritty.toml"

# `omakma theme` and `omakma font` recopy these two, so every theme's and every
# font's copy counts as one of ours.
remove_installed_config "$HOME/.config/alacritty/theme.toml" \
  "$OMAKMA_PATH"/themes/*/alacritty.toml

remove_installed_config "$HOME/.config/alacritty/font.toml" \
  "$OMAKMA_PATH"/configs/alacritty/fonts/*.toml

# font-size.toml is the exception: `omakma font > Change size` rewrites the size
# line in place rather than recopying, so a changed size reads here as a user
# edit and the file stays behind.
remove_installed_config "$HOME/.config/alacritty/font-size.toml" \
  "$OMAKMA_PATH/configs/alacritty/font-size.toml"

restore_config_backup "$HOME/.config/alacritty/alacritty.toml" \
  "$HOME/.config/alacritty/theme.toml" \
  "$HOME/.config/alacritty/font.toml" \
  "$HOME/.config/alacritty/font-size.toml"

remove_empty_dir "$HOME/.config/alacritty"
