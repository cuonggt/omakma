brew_app_uninstall fastfetch

# The installer writes config.jsonc only when there is none, so a file that no
# longer matches Omakma's copy was never ours and stays.
remove_installed_config "$HOME/.config/fastfetch/config.jsonc" \
  "$OMAKMA_PATH/configs/fastfetch.jsonc"

remove_empty_dir "$HOME/.config/fastfetch"
