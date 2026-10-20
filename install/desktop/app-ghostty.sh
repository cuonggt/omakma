app_install ghostty

# config is the file a Ghostty user is most likely to have written themselves,
# and the bundled themes land in a directory they may also be using, so both go
# through copy_config rather than cp -- it keeps the original as <file>.bak and
# costs nothing when there is none. It creates the directory too.
copy_config "$OMAKMA_PATH/configs/ghostty/config" "$HOME/.config/ghostty/config"

for GHOSTTY_THEME in "$OMAKMA_PATH"/configs/ghostty/themes/*; do
  copy_config "$GHOSTTY_THEME" "$HOME/.config/ghostty/themes/$(basename "$GHOSTTY_THEME")"
done
