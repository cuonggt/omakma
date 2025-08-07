THEME_NAMES=("Default" "Catppuccin" "Nord" "Everforest" "Rose Pine" "Ristretto" "Solarized")
THEME=$(gum choose "${THEME_NAMES[@]}" "<< Back" --header "Choose your theme" --height 10 | tr '[:upper:]' '[:lower:]' | gsed 's/ /-/g')

if [ -n "$THEME" ] && [ "$THEME" != "<<-back" ]; then
  cp $OMAKMA_PATH/themes/$THEME/alacritty.toml $HOME/.config/alacritty/theme.toml
  cp $OMAKMA_PATH/themes/$THEME/zellij.kdl ~/.config/zellij/themes/$THEME.kdl
  gsed -i "s/theme \".*\"/theme \"$THEME\"/g" ~/.config/zellij/config.kdl
  cp $OMAKMA_PATH/themes/$THEME/neovim.lua $HOME/.config/nvim/lua/plugins/theme.lua

  source $OMAKMA_PATH/themes/$THEME/sublime.sh
  source $OMAKMA_PATH/themes/$THEME/vscode.sh
fi

source $OMAKMA_PATH/bin/omakma-sub/menu.sh
