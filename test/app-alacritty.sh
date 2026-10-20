# Alacritty: the installer only copies files, so these cases run it for real and
# then uninstall, which is the only way to cover the .bak round trip.

ALACRITTY_CONFIG="$OMAKMA_PATH/configs/alacritty.toml"

echo "a config the user already had is backed up, then handed back"
HOME_DIR=$(sandbox_home alacritty-existing)
mkdir -p "$HOME_DIR/.config/alacritty"
printf '%s\n' "# the user's own" "live_config_reload = true" >"$HOME_DIR/.config/alacritty/alacritty.toml"
cp "$HOME_DIR/.config/alacritty/alacritty.toml" "$TEST_SANDBOX/alacritty-existing.orig"

run_script "$HOME_DIR" install desktop/app-alacritty.sh
assert_same "installer wrote Omakma's config" "$HOME_DIR/.config/alacritty/alacritty.toml" "$ALACRITTY_CONFIG"
assert_same "installer kept the original as .bak" "$HOME_DIR/.config/alacritty/alacritty.toml.bak" "$TEST_SANDBOX/alacritty-existing.orig"

run_script "$HOME_DIR" uninstall desktop/app-alacritty.sh
assert_same "uninstaller restored it byte for byte" "$HOME_DIR/.config/alacritty/alacritty.toml" "$TEST_SANDBOX/alacritty-existing.orig"
assert_gone "the .bak is consumed, not left lying about" "$HOME_DIR/.config/alacritty/alacritty.toml.bak"
assert_gone "theme.toml removed" "$HOME_DIR/.config/alacritty/theme.toml"
assert_gone "font.toml removed" "$HOME_DIR/.config/alacritty/font.toml"
assert_gone "font-size.toml removed" "$HOME_DIR/.config/alacritty/font-size.toml"
assert_exists "directory kept, it holds the user's file" "$HOME_DIR/.config/alacritty"
assert_says "says it restored the backup" "Restored"

echo "nothing of the user's to begin with"
HOME_DIR=$(sandbox_home alacritty-clean)
run_script "$HOME_DIR" install desktop/app-alacritty.sh
assert_gone "no .bak invented" "$HOME_DIR/.config/alacritty/alacritty.toml.bak"
run_script "$HOME_DIR" uninstall desktop/app-alacritty.sh
assert_gone "whole directory pruned" "$HOME_DIR/.config/alacritty"

echo "Omakma's config edited after installing"
HOME_DIR=$(sandbox_home alacritty-edited)
run_script "$HOME_DIR" install desktop/app-alacritty.sh
printf '\n# my tweak\n' >>"$HOME_DIR/.config/alacritty/alacritty.toml"
run_script "$HOME_DIR" uninstall desktop/app-alacritty.sh
assert_exists "edited alacritty.toml kept" "$HOME_DIR/.config/alacritty/alacritty.toml"
assert_gone "theme.toml still removed" "$HOME_DIR/.config/alacritty/theme.toml"
assert_exists "directory kept" "$HOME_DIR/.config/alacritty"

echo "theme and font switched after installing"
HOME_DIR=$(sandbox_home alacritty-switched)
run_script "$HOME_DIR" install desktop/app-alacritty.sh
cp "$OMAKMA_PATH/themes/nord/alacritty.toml" "$HOME_DIR/.config/alacritty/theme.toml"
cp "$OMAKMA_PATH/configs/alacritty/fonts/MesloLGS.toml" "$HOME_DIR/.config/alacritty/font.toml"
run_script "$HOME_DIR" uninstall desktop/app-alacritty.sh
assert_gone "any theme's theme.toml counts as ours" "$HOME_DIR/.config/alacritty/theme.toml"
assert_gone "any font's font.toml counts as ours" "$HOME_DIR/.config/alacritty/font.toml"
assert_gone "whole directory pruned" "$HOME_DIR/.config/alacritty"

echo "font size changed in place, which cannot be matched"
HOME_DIR=$(sandbox_home alacritty-resized)
run_script "$HOME_DIR" install desktop/app-alacritty.sh
rewrite_line "$HOME_DIR/.config/alacritty/font-size.toml" "size = " "size = 12"
run_script "$HOME_DIR" uninstall desktop/app-alacritty.sh
assert_exists "the resized font-size.toml stays" "$HOME_DIR/.config/alacritty/font-size.toml"
assert_gone "everything matchable still goes" "$HOME_DIR/.config/alacritty/alacritty.toml"

echo "installer re-run from \`omakma install\`, then uninstalled"
HOME_DIR=$(sandbox_home alacritty-rerun)
run_script "$HOME_DIR" install desktop/app-alacritty.sh
run_script "$HOME_DIR" install desktop/app-alacritty.sh
assert_gone "re-running backs up no config of Omakma's own" "$HOME_DIR/.config/alacritty/alacritty.toml.bak"
assert_gone "nor theme.toml's" "$HOME_DIR/.config/alacritty/theme.toml.bak"
run_script "$HOME_DIR" uninstall desktop/app-alacritty.sh
assert_gone "so uninstalling still clears the directory" "$HOME_DIR/.config/alacritty"

echo "nothing installed"
HOME_DIR=$(sandbox_home alacritty-absent)
run_script "$HOME_DIR" uninstall desktop/app-alacritty.sh
assert_gone "no config directory conjured up" "$HOME_DIR/.config/alacritty"
