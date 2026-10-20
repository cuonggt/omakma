# Ghostty: the installer only copies files, so these cases run it for real.
# config is rewritten line-by-line in place by `omakma theme`, `omakma font` and
# the font-size menu, so once any of those has run it cannot be matched.

GHOSTTY_CONFIG="$OMAKMA_PATH/configs/ghostty/config"

echo "a config the user already had is backed up, then handed back"
HOME_DIR=$(sandbox_home ghostty-existing)
mkdir -p "$HOME_DIR/.config/ghostty"
printf '%s\n' "# the user's own" "background-opacity = 0.9" >"$HOME_DIR/.config/ghostty/config"
cp "$HOME_DIR/.config/ghostty/config" "$TEST_SANDBOX/ghostty-existing.orig"

run_script "$HOME_DIR" install desktop/app-ghostty.sh
assert_same "installer wrote Omakma's config" "$HOME_DIR/.config/ghostty/config" "$GHOSTTY_CONFIG"
assert_same "installer kept the original as .bak" "$HOME_DIR/.config/ghostty/config.bak" "$TEST_SANDBOX/ghostty-existing.orig"

run_script "$HOME_DIR" uninstall desktop/app-ghostty.sh
assert_same "uninstaller restored it byte for byte" "$HOME_DIR/.config/ghostty/config" "$TEST_SANDBOX/ghostty-existing.orig"
assert_gone "the .bak is consumed, not left lying about" "$HOME_DIR/.config/ghostty/config.bak"
assert_gone "the bundled theme removed" "$HOME_DIR/.config/ghostty/themes/ristretto"
assert_gone "emptied themes/ pruned" "$HOME_DIR/.config/ghostty/themes"
assert_exists "directory kept, it holds the user's file" "$HOME_DIR/.config/ghostty"

echo "nothing of the user's to begin with"
HOME_DIR=$(sandbox_home ghostty-clean)
run_script "$HOME_DIR" install desktop/app-ghostty.sh
assert_exists "bundled theme installed" "$HOME_DIR/.config/ghostty/themes/ristretto"
assert_gone "no .bak invented" "$HOME_DIR/.config/ghostty/config.bak"
run_script "$HOME_DIR" uninstall desktop/app-ghostty.sh
assert_gone "whole directory pruned" "$HOME_DIR/.config/ghostty"

echo "theme switched in place by \`omakma theme\`"
HOME_DIR=$(sandbox_home ghostty-themed)
run_script "$HOME_DIR" install desktop/app-ghostty.sh
rewrite_line "$HOME_DIR/.config/ghostty/config" "theme = " "theme = Nord"
run_script "$HOME_DIR" uninstall desktop/app-ghostty.sh
assert_exists "the rewritten config stays" "$HOME_DIR/.config/ghostty/config"
assert_gone "the bundled theme still goes" "$HOME_DIR/.config/ghostty/themes/ristretto"
assert_exists "directory kept" "$HOME_DIR/.config/ghostty"
assert_says "says it kept config" "config: it differs"

echo "a theme file of the user's own sitting alongside Omakma's"
HOME_DIR=$(sandbox_home ghostty-usertheme)
run_script "$HOME_DIR" install desktop/app-ghostty.sh
echo "background = 1e1e1e" >"$HOME_DIR/.config/ghostty/themes/mine"
run_script "$HOME_DIR" uninstall desktop/app-ghostty.sh
assert_exists "the user's theme kept" "$HOME_DIR/.config/ghostty/themes/mine"
assert_gone "Omakma's theme removed from under it" "$HOME_DIR/.config/ghostty/themes/ristretto"
assert_exists "themes/ kept, it is not empty" "$HOME_DIR/.config/ghostty/themes"

echo "installer re-run from \`omakma install\`, then uninstalled"
HOME_DIR=$(sandbox_home ghostty-rerun)
run_script "$HOME_DIR" install desktop/app-ghostty.sh
run_script "$HOME_DIR" install desktop/app-ghostty.sh
assert_gone "re-running backs up no config of Omakma's own" "$HOME_DIR/.config/ghostty/config.bak"
assert_gone "nor the bundled theme's" "$HOME_DIR/.config/ghostty/themes/ristretto.bak"
run_script "$HOME_DIR" uninstall desktop/app-ghostty.sh
assert_gone "so uninstalling still clears the directory" "$HOME_DIR/.config/ghostty"

echo "nothing installed"
HOME_DIR=$(sandbox_home ghostty-absent)
run_script "$HOME_DIR" uninstall desktop/app-ghostty.sh
assert_gone "no config directory conjured up" "$HOME_DIR/.config/ghostty"
