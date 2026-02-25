brew list zellij &>/dev/null || brew install zellij

mkdir -p ~/.config/zellij/themes
[ ! -f "$HOME/.config/zellij/config.kdl" ] && cp "$OMAKMA_PATH/configs/zellij.kdl" ~/.config/zellij/config.kdl
cp "$OMAKMA_PATH/themes/default/zellij.kdl" ~/.config/zellij/themes/default.kdl
