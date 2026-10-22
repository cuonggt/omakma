# Guarded on the command rather than on brew, so an nvim installed by other
# means is left alone.
if ! command -v nvim &> /dev/null; then
  brew install neovim || install_unavailable neovim
fi

# Only attempt to set configuration if Neovim has never been run
if [ ! -d "$HOME/.config/nvim" ]; then
  # Everything below writes into the clone, so there is nothing to configure if
  # it did not arrive.
  if ! git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"; then
    download_failed "LazyVim starter"

    return 0 2>/dev/null || exit 0
  fi

  # Remove the .git folder, so you can add it to your own repo later
  rm -rf ~/.config/nvim/.git

  # Make everything match the terminal transparency
  mkdir -p "$HOME/.config/nvim/plugin/after"
  cp "$OMAKMA_PATH/configs/neovim/transparency.lua" "$HOME/.config/nvim/plugin/after/"

  # Default to Tokyo Night theme. The starter ships lua/plugins, but creating it
  # costs nothing and the copy below is otherwise one upstream layout change
  # away from ending the install.
  mkdir -p "$HOME/.config/nvim/lua/plugins"
  cp "$OMAKMA_PATH/themes/default/neovim.lua" "$HOME/.config/nvim/lua/plugins/theme.lua"

  # Enable default extras
  cp "$OMAKMA_PATH/configs/neovim/lazyvim.json" "$HOME/.config/nvim/lazyvim.json"
fi
