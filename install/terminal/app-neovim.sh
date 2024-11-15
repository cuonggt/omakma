if ! command -v nvim &> /dev/null; then
  brew install neovim
fi

# Only attempt to set configuration if Neovim has never been run
if [ ! -d "$HOME/.config/nvim" ]; then
  # Use LazyVim
  git clone https://github.com/LazyVim/starter $HOME/.config/nvim

  # Remove the .git folder, so you can add it to your own repo later
	rm -rf ~/.config/nvim/.git

  # Make everything match the terminal transparency
  mkdir -p $HOME/.config/nvim/plugin/after
  cp $HOME/.local/share/omakma/configs/neovim/transparency.lua $HOME/.config/nvim/plugin/after/

  # Default to Tokyo Night theme
  cp $HOME/.local/share/omakma/themes/default/neovim.lua $HOME/.config/nvim/lua/plugins/theme.lua

  # Enable default extras
  cp $HOME/.local/share/omakma/configs/neovim/lazyvim.json $HOME/.config/nvim/lazyvim.json
fi
