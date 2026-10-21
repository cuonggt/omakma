# iTerm2: the uninstaller patches ~/Library/Preferences/com.googlecode.iterm2.plist
# with python, the same way the installer writes it. These cases build a plist,
# run the uninstaller against a sandbox HOME, and read the result back.
#
# Explicit subshells rather than run_script, because `pgrep` has to be
# controlled: the uninstaller skips the plist while iTerm2 is running, since
# iTerm2 holds its preferences in memory and writes them back when it quits.

ITERM_PLIST_REL="Library/Preferences/com.googlecode.iterm2.plist"

# make_iterm2_plist <plist> <profile-names...>
# A plist whose first named profile carries Omakma's guid, with the appearance
# keys the installer sets.
make_iterm2_plist() {
  python3 -I - "$@" <<'PY'
import plistlib, pathlib, sys

path, names = sys.argv[1], sys.argv[2:]
profiles = [{"Name": n, "Guid": "guid-" + n} for n in names]
prefs = {
    "New Bookmarks": profiles,
    "Default Bookmark Guid": "guid-omakma",
    "TabStyleWithAutomaticOption": 5,
    "StatusBarPosition": 1,
}
pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
with open(path, "wb") as f:
    plistlib.dump(prefs, f)
PY
}

# dump_iterm2_plist <plist>
dump_iterm2_plist() {
  python3 -I - "$1" <<'PY'
import plistlib, sys

try:
    with open(sys.argv[1], "rb") as f:
        prefs = plistlib.load(f)
except FileNotFoundError:
    print("no_plist=yes")
    raise SystemExit(0)

print("has_new_bookmarks=%s" % ("New Bookmarks" in prefs))
print("names=%s" % ",".join((p.get("Name") or "?") for p in prefs.get("New Bookmarks") or []))
print("default_guid=%s" % prefs.get("Default Bookmark Guid"))
print("tabstyle=%s" % prefs.get("TabStyleWithAutomaticOption"))
print("statusbar=%s" % prefs.get("StatusBarPosition"))
PY
}

# run_iterm2_uninstaller <home> <running: yes|no>
run_iterm2_uninstaller() {
  TEST_OUTPUT=$(
    exec 2>&1
    HOME="$1"
    export HOME
    source "$OMAKMA_PATH/defaults/bash/functions"
    app_uninstall() { :; }
    if [ "$2" = yes ]; then
      pgrep() { return 0; }
    else
      pgrep() { return 1; }
    fi
    source "$OMAKMA_PATH/uninstall/desktop/app-iterm2.sh"
  )
}

echo "Omakma's profile goes, a profile of the user's stays"
HOME_DIR=$(sandbox_home iterm2-mixed)
make_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL" omakma "Work"
run_iterm2_uninstaller "$HOME_DIR" no
assert_says "it reports what it cleared" "Cleared Omakma's iTerm2 profile"
assert_says "and is honest that the originals are gone for good" "cannot be brought back"
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"names=Work"*) test_pass "only the user's profile is left" ;;
*) test_fail "the remaining profiles are wrong: $PLIST_AFTER" ;;
esac
case "$PLIST_AFTER" in
*"default_guid=None"*) test_pass "the default-profile guid that pointed at Omakma's is cleared" ;;
*) test_fail "the default guid still points somewhere: $PLIST_AFTER" ;;
esac
case "$PLIST_AFTER" in
*"tabstyle=None"*"statusbar=None"*) test_pass "the appearance keys it set are cleared" ;;
*) test_fail "appearance keys remain: $PLIST_AFTER" ;;
esac

echo "with nothing but Omakma's profile, the key is dropped so iTerm2 rebuilds a default"
HOME_DIR=$(sandbox_home iterm2-only-ours)
make_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL" omakma
run_iterm2_uninstaller "$HOME_DIR" no
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"has_new_bookmarks=False"*) test_pass "an empty profile list is not left behind" ;;
*) test_fail "New Bookmarks was left in place: $PLIST_AFTER" ;;
esac

echo "appearance keys the user has since changed are left alone"
HOME_DIR=$(sandbox_home iterm2-user-appearance)
make_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL" omakma "Work"
python3 -I - "$HOME_DIR/$ITERM_PLIST_REL" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as f:
    prefs = plistlib.load(f)
prefs["TabStyleWithAutomaticOption"] = 2
prefs["StatusBarPosition"] = 0
with open(sys.argv[1], "wb") as f:
    plistlib.dump(prefs, f)
PY
run_iterm2_uninstaller "$HOME_DIR" no
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"tabstyle=2"*"statusbar=0"*) test_pass "values the user changed are kept" ;;
*) test_fail "it overwrote the user's appearance settings: $PLIST_AFTER" ;;
esac

echo "a plist with no Omakma profile is not touched"
HOME_DIR=$(sandbox_home iterm2-none-ours)
make_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL" "Work" "Personal"
run_iterm2_uninstaller "$HOME_DIR" no
assert_says "it says there is nothing to clear" "No Omakma iTerm2 profile found"
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"names=Work,Personal"*) test_pass "both of the user's profiles are intact" ;;
*) test_fail "profiles were disturbed: $PLIST_AFTER" ;;
esac

echo "no plist at all is handled"
HOME_DIR=$(sandbox_home iterm2-no-plist)
run_iterm2_uninstaller "$HOME_DIR" no
assert_says "it says so rather than failing" "No iTerm2 preferences found"

echo "a running iTerm2 would undo the change, so the plist is left for later"
HOME_DIR=$(sandbox_home iterm2-running)
make_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL" omakma "Work"
mkdir -p "$HOME_DIR/Library/Application Support/iTerm2/DynamicProfiles"
echo "{}" >"$HOME_DIR/Library/Application Support/iTerm2/DynamicProfiles/omakma.json"
run_iterm2_uninstaller "$HOME_DIR" yes
assert_says "it explains why it stopped" "iTerm2 is running and would write its preferences back"
assert_says "and how to finish" "Quit iTerm2, then run this uninstaller again"
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"names=omakma,Work"*) test_pass "the plist is untouched" ;;
*) test_fail "it patched the plist underneath a running iTerm2: $PLIST_AFTER" ;;
esac
assert_gone "the dynamic profile is still removed, which is safe either way" "$HOME_DIR/Library/Application Support/iTerm2/DynamicProfiles/omakma.json"
