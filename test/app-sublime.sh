# Sublime Text: the installer downloads Package Control and clones seven
# packages, so it cannot be run here. These cases build the installed state
# directly and check what the uninstaller is willing to remove.
#
# The clones are made with a real `git init` plus a remote, since
# remove_installed_clone decides ownership from the remote url rather than from
# content -- a clone cannot be byte-matched the way a config file can.

SUBLIME_REL="Library/Application Support/Sublime Text"

# fake_clone <dir> <url>
fake_clone() {
  mkdir -p "$1"
  git -C "$1" init --quiet
  git -C "$1" remote add origin "$2"
}

echo "the settings files are removed and the user's originals handed back"
HOME_DIR=$(sandbox_home sublime-settings)
mkdir -p "$HOME_DIR/$SUBLIME_REL/Packages/User"
cp "$OMAKMA_PATH/configs/sublime/Preferences.sublime-settings" "$HOME_DIR/$SUBLIME_REL/Packages/User/Preferences.sublime-settings"
cp "$OMAKMA_PATH/configs/sublime/LSP.sublime-settings" "$HOME_DIR/$SUBLIME_REL/Packages/User/LSP.sublime-settings"
cp "$OMAKMA_PATH/configs/sublime/minimap_setting.py" "$HOME_DIR/$SUBLIME_REL/Packages/User/minimap_setting.py"
printf '%s\n' '{ "font_size": 20 }' >"$TEST_SANDBOX/sublime-prefs.orig"
cp "$TEST_SANDBOX/sublime-prefs.orig" "$HOME_DIR/$SUBLIME_REL/Packages/User/Preferences.sublime-settings.bak"

run_script "$HOME_DIR" uninstall desktop/app-sublime.sh
assert_same "the user's Preferences are restored from .bak" "$HOME_DIR/$SUBLIME_REL/Packages/User/Preferences.sublime-settings" "$TEST_SANDBOX/sublime-prefs.orig"
assert_gone "LSP settings removed, with no .bak to restore" "$HOME_DIR/$SUBLIME_REL/Packages/User/LSP.sublime-settings"
assert_gone "minimap_setting.py removed" "$HOME_DIR/$SUBLIME_REL/Packages/User/minimap_setting.py"

echo "settings edited after install are kept"
HOME_DIR=$(sandbox_home sublime-edited)
mkdir -p "$HOME_DIR/$SUBLIME_REL/Packages/User"
printf '%s\n' '{ "my_own": true }' >"$HOME_DIR/$SUBLIME_REL/Packages/User/Preferences.sublime-settings"
run_script "$HOME_DIR" uninstall desktop/app-sublime.sh
assert_exists "the edited Preferences stay" "$HOME_DIR/$SUBLIME_REL/Packages/User/Preferences.sublime-settings"
assert_says "and it says so" "Preferences.sublime-settings: it differs"

echo "a package is removed only while it is still the clone Omakma made"
HOME_DIR=$(sandbox_home sublime-packages)
mkdir -p "$HOME_DIR/$SUBLIME_REL/Packages"
fake_clone "$HOME_DIR/$SUBLIME_REL/Packages/LSP" "https://github.com/sublimelsp/LSP.git"
fake_clone "$HOME_DIR/$SUBLIME_REL/Packages/AFileIcon" "https://github.com/SublimeText/AFileIcon.git"
# The installer skips a package that is already there, so one with another
# origin was never Omakma's.
fake_clone "$HOME_DIR/$SUBLIME_REL/Packages/LSP-json" "https://github.com/someone/their-own-fork.git"
# Nor is a directory that is not a clone at all.
mkdir -p "$HOME_DIR/$SUBLIME_REL/Packages/AdvancedNewFile"
echo "mine" >"$HOME_DIR/$SUBLIME_REL/Packages/AdvancedNewFile/notes.txt"

run_script "$HOME_DIR" uninstall desktop/app-sublime.sh
assert_gone "Omakma's LSP clone is removed" "$HOME_DIR/$SUBLIME_REL/Packages/LSP"
assert_gone "and its AFileIcon clone" "$HOME_DIR/$SUBLIME_REL/Packages/AFileIcon"
assert_exists "a clone from another remote is kept" "$HOME_DIR/$SUBLIME_REL/Packages/LSP-json"
assert_exists "and a directory that is not a clone" "$HOME_DIR/$SUBLIME_REL/Packages/AdvancedNewFile/notes.txt"
assert_says "it says what it kept" "it is not the clone Omakma made"

echo "a colour scheme package cloned by omakma theme is removed too"
HOME_DIR=$(sandbox_home sublime-theme-package)
mkdir -p "$HOME_DIR/$SUBLIME_REL/Packages"
fake_clone "$HOME_DIR/$SUBLIME_REL/Packages/Nord" "https://github.com/nordtheme/sublime-text.git"
run_script "$HOME_DIR" uninstall desktop/app-sublime.sh
assert_gone "the theme's package is removed" "$HOME_DIR/$SUBLIME_REL/Packages/Nord"

echo "Package Control is left alone, since its owner cannot be established"
HOME_DIR=$(sandbox_home sublime-package-control)
mkdir -p "$HOME_DIR/$SUBLIME_REL/Installed Packages"
echo "binary-ish" >"$HOME_DIR/$SUBLIME_REL/Installed Packages/Package Control.sublime-package"
run_script "$HOME_DIR" uninstall desktop/app-sublime.sh
assert_exists "Package Control stays" "$HOME_DIR/$SUBLIME_REL/Installed Packages/Package Control.sublime-package"

echo "an install of nothing but Omakma's own files clears the tree"
HOME_DIR=$(sandbox_home sublime-all-ours)
mkdir -p "$HOME_DIR/$SUBLIME_REL/Packages/User"
cp "$OMAKMA_PATH/configs/sublime/Preferences.sublime-settings" "$HOME_DIR/$SUBLIME_REL/Packages/User/Preferences.sublime-settings"
cp "$OMAKMA_PATH/configs/sublime/LSP.sublime-settings" "$HOME_DIR/$SUBLIME_REL/Packages/User/LSP.sublime-settings"
cp "$OMAKMA_PATH/configs/sublime/minimap_setting.py" "$HOME_DIR/$SUBLIME_REL/Packages/User/minimap_setting.py"
fake_clone "$HOME_DIR/$SUBLIME_REL/Packages/LSP" "https://github.com/sublimelsp/LSP.git"
run_script "$HOME_DIR" uninstall desktop/app-sublime.sh
assert_gone "the whole Sublime Text directory is pruned" "$HOME_DIR/$SUBLIME_REL"

echo "nothing installed"
HOME_DIR=$(sandbox_home sublime-absent)
run_script "$HOME_DIR" uninstall desktop/app-sublime.sh
assert_gone "no directory conjured up" "$HOME_DIR/$SUBLIME_REL"
