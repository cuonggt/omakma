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
print("omakma_guid=%s" % ",".join(p.get("Guid") or "?" for p in prefs.get("New Bookmarks") or [] if p.get("Name") == "omakma"))
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

# run_iterm2_installer <home> <running: yes|no>
run_iterm2_installer() {
  TEST_OUTPUT=$(
    exec 2>&1
    HOME="$1"
    export HOME
    source "$OMAKMA_PATH/defaults/bash/functions"
    app_install() { :; }
    if [ "$2" = yes ]; then
      pgrep() { return 0; }
    else
      pgrep() { return 1; }
    fi
    source "$OMAKMA_PATH/install/desktop/app-iterm2.sh"
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

echo "the installer keeps the profiles the user already had"
HOME_DIR=$(sandbox_home iterm2-install-existing)
make_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL" "Work" "Personal"
cp "$HOME_DIR/$ITERM_PLIST_REL" "$TEST_SANDBOX/iterm2-install-existing.orig"

run_iterm2_installer "$HOME_DIR" no
assert_says "it says what it did" "alongside your 2 existing profile(s)"
assert_same "the plist is backed up before being touched" "$HOME_DIR/$ITERM_PLIST_REL.bak" "$TEST_SANDBOX/iterm2-install-existing.orig"
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"names=Work,Personal,omakma"*) test_pass "both of the user's profiles survive, with Omakma's added" ;;
*) test_fail "profiles were lost: $PLIST_AFTER" ;;
esac

echo "the installer is safe to re-run"
run_iterm2_installer "$HOME_DIR" no
PLIST_RERUN=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_RERUN" in
*"names=Work,Personal,omakma"*) test_pass "no second Omakma profile is added" ;;
*) test_fail "re-running changed the profile list: $PLIST_RERUN" ;;
esac
FIRST_GUID=$(echo "$PLIST_AFTER" | sed -n 's/^omakma_guid=//p')
SECOND_GUID=$(echo "$PLIST_RERUN" | sed -n 's/^omakma_guid=//p')
if [ -n "$FIRST_GUID" ] && [ "$FIRST_GUID" = "$SECOND_GUID" ]; then
  test_pass "the profile keeps its guid, so anything bound to it still works"
else
  test_fail "the guid changed on re-run ($FIRST_GUID -> $SECOND_GUID)"
fi
assert_same "the backup is not replaced with Omakma's own copy" "$HOME_DIR/$ITERM_PLIST_REL.bak" "$TEST_SANDBOX/iterm2-install-existing.orig"

echo "a default profile the user has since chosen is left alone"
HOME_DIR=$(sandbox_home iterm2-install-default)
make_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL" "Work"
run_iterm2_installer "$HOME_DIR" no
python3 -I - "$HOME_DIR/$ITERM_PLIST_REL" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as f:
    prefs = plistlib.load(f)
prefs["Default Bookmark Guid"] = "guid-Work"
prefs["TabStyleWithAutomaticOption"] = 2
with open(sys.argv[1], "wb") as f:
    plistlib.dump(prefs, f)
PY
run_iterm2_installer "$HOME_DIR" no
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"default_guid=guid-Work"*) test_pass "their default profile stays theirs" ;;
*) test_fail "the installer took the default back: $PLIST_AFTER" ;;
esac
case "$PLIST_AFTER" in
*"tabstyle=2"*) test_pass "and the tab style they chose is kept" ;;
*) test_fail "the installer overwrote their tab style: $PLIST_AFTER" ;;
esac

echo "a first install does claim the default and the appearance keys"
HOME_DIR=$(sandbox_home iterm2-install-fresh)
run_iterm2_installer "$HOME_DIR" no
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"names=omakma"*) test_pass "the profile is created" ;;
*) test_fail "no profile was written: $PLIST_AFTER" ;;
esac
case "$PLIST_AFTER" in
*"tabstyle=5"*"statusbar=1"*) test_pass "the appearance keys are set" ;;
*) test_fail "appearance keys were not set: $PLIST_AFTER" ;;
esac
assert_gone "nothing is backed up when there was no plist" "$HOME_DIR/$ITERM_PLIST_REL.bak"

echo "the installer defers to a running iTerm2 rather than losing the write"
HOME_DIR=$(sandbox_home iterm2-install-running)
make_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL" "Work"
run_iterm2_installer "$HOME_DIR" yes
assert_says "it explains why it stopped" "iTerm2 is running and would overwrite its preferences"
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"names=Work"*) test_pass "the plist is untouched" ;;
*) test_fail "it wrote underneath a running iTerm2: $PLIST_AFTER" ;;
esac

echo "install then uninstall leaves the user's profiles as they were"
HOME_DIR=$(sandbox_home iterm2-round-trip)
make_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL" "Work" "Personal"
run_iterm2_installer "$HOME_DIR" no
run_iterm2_uninstaller "$HOME_DIR" no
PLIST_AFTER=$(dump_iterm2_plist "$HOME_DIR/$ITERM_PLIST_REL")
case "$PLIST_AFTER" in
*"names=Work,Personal"*) test_pass "both profiles are back to just the user's" ;;
*) test_fail "the round trip did not leave the user's profiles: $PLIST_AFTER" ;;
esac
case "$PLIST_AFTER" in
*"tabstyle=None"*"statusbar=None"*) test_pass "and the appearance keys are cleared again" ;;
*) test_fail "appearance keys survived the round trip: $PLIST_AFTER" ;;
esac
assert_exists "the install-time backup is still there to fall back on" "$HOME_DIR/$ITERM_PLIST_REL.bak"
