THEME_NAMES=("Default" "Catppuccin" "Nord" "Everforest" "Rose Pine" "Ristretto" "Solarized")
# tr rather than gsed for the slug: gnu-sed is installable but skippable, and a
# missing one here would silently blank the choice.
THEME=$(gum choose "${THEME_NAMES[@]}" "<< Back" --header "Choose your theme" --height 10 | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

if [ -n "$THEME" ] && [ "$THEME" != "<<-back" ]; then
  # Each of these is skipped if the app's config is not there, so switching
  # theme after uninstalling something says nothing rather than failing.
  update_config "$OMAKMA_PATH/themes/$THEME/alacritty.toml" "$HOME/.config/alacritty/theme.toml"

  GHOSTTY_THEME=$(cat "$OMAKMA_PATH/themes/$THEME/ghostty")
  edit_config "$HOME/.config/ghostty/config" "s/^theme = .*$/theme = $GHOSTTY_THEME/g"

  update_config "$OMAKMA_PATH/themes/$THEME/zellij.kdl" "$HOME/.config/zellij/themes/$THEME.kdl"
  edit_config "$HOME/.config/zellij/config.kdl" "s/theme \".*\"/theme \"$THEME\"/g"

  update_config "$OMAKMA_PATH/themes/$THEME/neovim.lua" "$HOME/.config/nvim/lua/plugins/theme.lua"

  source "$OMAKMA_PATH/themes/$THEME/sublime.sh"
  source "$OMAKMA_PATH/themes/$THEME/vscode.sh"
fi

source "$OMAKMA_PATH/bin/omakma-sub/menu.sh"
