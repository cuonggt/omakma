# Alacritty is a GPU-powered and highly extensible terminal. See https://alacritty.org/
if [[ ! -d /Applications/Alacritty.app ]]; then
  brew install alacritty
fi

mkdir -p "$HOME/.config/alacritty"
cp "$OMAKMA_PATH/configs/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
cp "$OMAKMA_PATH/themes/default/alacritty.toml" "$HOME/.config/alacritty/theme.toml"
cp "$OMAKMA_PATH/configs/alacritty/fonts/JetBrainsMono.toml" "$HOME/.config/alacritty/font.toml"
cp "$OMAKMA_PATH/configs/alacritty/font-size.toml" "$HOME/.config/alacritty/font-size.toml"
