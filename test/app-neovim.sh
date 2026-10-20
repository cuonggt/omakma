# Neovim: the installer clones LazyVim from the network, so these cases build
# the installed state directly instead of running it. What is under test is the
# uninstaller, which must never remove ~/.config/nvim: Omakma strips .git from
# the starter so the user can adopt it, leaving the clone indistinguishable from
# a config they wrote.

echo "Omakma's three files, default theme, alongside the user's own"
HOME_DIR=$(sandbox_home nvim-default)
mkdir -p "$HOME_DIR/.config/nvim/plugin/after" "$HOME_DIR/.config/nvim/lua/plugins"
cp "$OMAKMA_PATH/configs/neovim/transparency.lua" "$HOME_DIR/.config/nvim/plugin/after/"
cp "$OMAKMA_PATH/configs/neovim/lazyvim.json" "$HOME_DIR/.config/nvim/lazyvim.json"
cp "$OMAKMA_PATH/themes/default/neovim.lua" "$HOME_DIR/.config/nvim/lua/plugins/theme.lua"
echo "-- the user's own init" >"$HOME_DIR/.config/nvim/init.lua"

run_script "$HOME_DIR" uninstall terminal/app-neovim.sh
assert_gone "transparency.lua removed" "$HOME_DIR/.config/nvim/plugin/after/transparency.lua"
assert_gone "lazyvim.json removed" "$HOME_DIR/.config/nvim/lazyvim.json"
assert_gone "theme.lua removed" "$HOME_DIR/.config/nvim/lua/plugins/theme.lua"
assert_gone "emptied plugin/ pruned" "$HOME_DIR/.config/nvim/plugin"
assert_exists "the user's init.lua kept" "$HOME_DIR/.config/nvim/init.lua"
assert_exists "the nvim config directory itself kept" "$HOME_DIR/.config/nvim"
assert_says "says it kept the config directory" "cannot tell its LazyVim starter"

echo "theme.lua edited by the user"
HOME_DIR=$(sandbox_home nvim-edited)
mkdir -p "$HOME_DIR/.config/nvim/lua/plugins"
echo "-- my own colourscheme" >"$HOME_DIR/.config/nvim/lua/plugins/theme.lua"

run_script "$HOME_DIR" uninstall terminal/app-neovim.sh
assert_exists "edited theme.lua kept" "$HOME_DIR/.config/nvim/lua/plugins/theme.lua"
assert_says "says it kept the edited file" "theme.lua: it differs"

echo "theme switched away from default"
HOME_DIR=$(sandbox_home nvim-nord)
mkdir -p "$HOME_DIR/.config/nvim/lua/plugins"
cp "$OMAKMA_PATH/themes/nord/neovim.lua" "$HOME_DIR/.config/nvim/lua/plugins/theme.lua"

run_script "$HOME_DIR" uninstall terminal/app-neovim.sh
assert_gone "a non-default theme's theme.lua is still ours" "$HOME_DIR/.config/nvim/lua/plugins/theme.lua"

echo "nothing installed"
HOME_DIR=$(sandbox_home nvim-absent)
run_script "$HOME_DIR" uninstall terminal/app-neovim.sh
assert_gone "no config directory conjured up" "$HOME_DIR/.config/nvim"
