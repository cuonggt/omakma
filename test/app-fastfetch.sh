# fastfetch: the installer writes config.jsonc only when there is none, so a
# file that does not match Omakma's copy was never ours.

echo "Omakma's own config"
HOME_DIR=$(sandbox_home fastfetch-omakma)
mkdir -p "$HOME_DIR/.config/fastfetch"
cp "$OMAKMA_PATH/configs/fastfetch.jsonc" "$HOME_DIR/.config/fastfetch/config.jsonc"

run_script "$HOME_DIR" uninstall terminal/app-fastfetch.sh
assert_gone "config removed" "$HOME_DIR/.config/fastfetch/config.jsonc"
assert_gone "emptied directory pruned" "$HOME_DIR/.config/fastfetch"

echo "a config the installer refused to touch"
HOME_DIR=$(sandbox_home fastfetch-user)
mkdir -p "$HOME_DIR/.config/fastfetch"
echo '{"modules":["title"]}' >"$HOME_DIR/.config/fastfetch/config.jsonc"

run_script "$HOME_DIR" uninstall terminal/app-fastfetch.sh
assert_exists "the user's config kept" "$HOME_DIR/.config/fastfetch/config.jsonc"
assert_exists "directory kept with it" "$HOME_DIR/.config/fastfetch"
assert_says "says it kept the config" "config.jsonc: it differs"

echo "nothing installed"
HOME_DIR=$(sandbox_home fastfetch-absent)
run_script "$HOME_DIR" uninstall terminal/app-fastfetch.sh
assert_gone "no config directory conjured up" "$HOME_DIR/.config/fastfetch"
