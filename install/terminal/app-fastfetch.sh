# Display system information in the terminal
brew install fastfetch

# Only attempt to set configuration if fastfetch is not already set
if [ ! -f "$HOME/.config/fastfetch/config.jsonc" ]; then
  # Use Omakma fastfetch config
  mkdir -p ~/.config/fastfetch
  cp ~/.local/share/omakma/configs/fastfetch.jsonc ~/.config/fastfetch/config.jsonc
fi
