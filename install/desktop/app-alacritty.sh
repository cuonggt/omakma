# Alacritty is a GPU-powered and highly extensible terminal. See https://alacritty.org/
if [ ! -d /Applications/Alacritty.app ]; then
  brew install alacritty
fi

mkdir -p $HOME/.config/alacritty
cp $HOME/.local/share/omakma/configs/alacritty.toml $HOME/.config/alacritty/alacritty.toml
cp $HOME/.local/share/omakma/themes/default/alacritty.toml $HOME/.config/alacritty/theme.toml
cp $HOME/.local/share/omakma/configs/alacritty/fonts/JetBrainsMono.toml $HOME/.config/alacritty/font.toml
cp $HOME/.local/share/omakma/configs/alacritty/font-size.toml $HOME/.config/alacritty/font-size.toml
