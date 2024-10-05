brew install zellij

mkdir -p ~/.config/zellij/themes
[ ! -f "$HOME/.config/zellij/config.kdl" ] && cp ~/.local/share/omakma/configs/zellij.kdl ~/.config/zellij/config.kdl
cp ~/.local/share/omakma/themes/default/zellij.kdl ~/.config/zellij/themes/default.kdl
