# Alacritty is a GPU-powered and highly extensible terminal. See https://alacritty.org/
brew_app_install alacritty

# Each of these lands on a path the user may already be keeping their own file
# at, so all four go through copy_config: it preserves the original as
# <file>.bak and costs nothing when there is no original to preserve. It also
# creates the directory, so there is no mkdir to do first.
copy_config "$OMAKMA_PATH/configs/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
copy_config "$OMAKMA_PATH/themes/default/alacritty.toml" "$HOME/.config/alacritty/theme.toml"
copy_config "$OMAKMA_PATH/configs/alacritty/fonts/JetBrainsMono.toml" "$HOME/.config/alacritty/font.toml"
copy_config "$OMAKMA_PATH/configs/alacritty/font-size.toml" "$HOME/.config/alacritty/font-size.toml"
