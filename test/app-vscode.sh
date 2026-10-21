# VS Code: the installer's only real action is the copy_config of settings.json
# -- the symlink needs sudo and the 33 extensions need `code` -- so it can be
# run for real here with those two stubbed, giving a genuine .bak round trip.

VSCODE_SETTINGS="Library/Application Support/Code/User/settings.json"

echo "a settings.json the user already had is backed up, then handed back"
HOME_DIR=$(sandbox_home vscode-existing)
mkdir -p "$HOME_DIR/Library/Application Support/Code/User"
printf '%s\n' '{ "editor.fontSize": 18 }' >"$HOME_DIR/$VSCODE_SETTINGS"
cp "$HOME_DIR/$VSCODE_SETTINGS" "$TEST_SANDBOX/vscode-existing.orig"

run_script "$HOME_DIR" install desktop/app-vscode.sh
assert_same "installer wrote Omakma's settings" "$HOME_DIR/$VSCODE_SETTINGS" "$OMAKMA_PATH/configs/vscode.json"
assert_same "installer kept the original as .bak" "$HOME_DIR/$VSCODE_SETTINGS.bak" "$TEST_SANDBOX/vscode-existing.orig"

run_script "$HOME_DIR" uninstall desktop/app-vscode.sh
assert_same "uninstaller restored it byte for byte" "$HOME_DIR/$VSCODE_SETTINGS" "$TEST_SANDBOX/vscode-existing.orig"
assert_gone "the .bak is consumed" "$HOME_DIR/$VSCODE_SETTINGS.bak"

echo "Omakma's own settings.json is removed"
HOME_DIR=$(sandbox_home vscode-clean)
run_script "$HOME_DIR" install desktop/app-vscode.sh
assert_same "installed" "$HOME_DIR/$VSCODE_SETTINGS" "$OMAKMA_PATH/configs/vscode.json"
run_script "$HOME_DIR" uninstall desktop/app-vscode.sh
assert_gone "settings.json removed" "$HOME_DIR/$VSCODE_SETTINGS"

echo "settings.json edited after install is kept"
HOME_DIR=$(sandbox_home vscode-edited)
run_script "$HOME_DIR" install desktop/app-vscode.sh
printf '\n// mine\n' >>"$HOME_DIR/$VSCODE_SETTINGS"
run_script "$HOME_DIR" uninstall desktop/app-vscode.sh
assert_exists "the edited settings stay" "$HOME_DIR/$VSCODE_SETTINGS"
assert_says "and it says so" "settings.json: it differs"

echo "the symlink is only removed when it is the one the installer made"
# /usr/local/bin/code cannot be sandboxed, so this is all that can be checked
# here: that the uninstaller reads the link before reaching for sudo, and so
# cannot delete a `code` belonging to something else.
VSCODE_UNINSTALLER=$(cat "$OMAKMA_PATH/uninstall/desktop/app-vscode.sh")
case "$VSCODE_UNINSTALLER" in
*'readlink /usr/local/bin/code'*) test_pass "it reads the link first" ;;
*) test_fail "it no longer checks the link before removing it" ;;
esac
# Indented, so it sits inside the check rather than running unconditionally.
case "$VSCODE_UNINSTALLER" in
*"
  sudo rm -f /usr/local/bin/code"*) test_pass "and the sudo sits inside that check" ;;
*) test_fail "the sudo is not guarded by the link check" ;;
esac
