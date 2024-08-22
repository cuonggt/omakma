if [ ! -d /Applications/Alacritty.app ]; then
  brew install alacritty
fi

mkdir -p ~/.config/alacritty
cp ~/.local/share/omakma/configs/alacritty.toml ~/.config/alacritty/alacritty.toml
cp ~/.local/share/omakma/themes/default/alacritty.toml ~/.config/alacritty/theme.toml
cp ~/.local/share/omakma/configs/alacritty/fonts/JetBrainsMono.toml ~/.config/alacritty/font.toml
cp ~/.local/share/omakma/configs/alacritty/font-size.toml ~/.config/alacritty/font-size.toml
