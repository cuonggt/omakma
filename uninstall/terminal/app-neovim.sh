brew_app_uninstall neovim

# Omakma clones the LazyVim starter into ~/.config/nvim and strips its .git so
# the user can adopt it, which leaves the clone indistinguishable from a config
# they wrote themselves. So remove only the files Omakma copied in on top and
# leave the directory: deleting a Neovim config that turns out to be the user's
# own is far worse than leaving a LazyVim starter behind.
remove_installed_config "$HOME/.config/nvim/plugin/after/transparency.lua" \
  "$OMAKMA_PATH/configs/neovim/transparency.lua"

remove_installed_config "$HOME/.config/nvim/lazyvim.json" \
  "$OMAKMA_PATH/configs/neovim/lazyvim.json"

# theme.lua is recopied by `omakma theme`, so any theme's copy counts as ours.
remove_installed_config "$HOME/.config/nvim/lua/plugins/theme.lua" \
  "$OMAKMA_PATH"/themes/*/neovim.lua

remove_empty_dir "$HOME/.config/nvim/plugin/after" "$HOME/.config/nvim/plugin"

if [[ -d "$HOME/.config/nvim" ]]; then
  echo "Kept $HOME/.config/nvim: Omakma cannot tell its LazyVim starter from your own config."
fi
