app_uninstall iterm2 || return 1 2>/dev/null || exit 1

# Safe to remove whether or not iTerm2 is running: iTerm2 reads dynamic profiles
# from disk rather than caching them in its preferences.
rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/omakma.json"

# iTerm2 holds its preferences in memory and writes them back when it quits, so
# clearing them underneath a running iTerm2 is silently undone.
if pgrep -qx iTerm2; then
  echo "iTerm2 is running and would write its preferences back when it quits."
  echo "Quit iTerm2, then run this uninstaller again to clear Omakma's profile."
else
  python3 - "$OMAKMA_PATH/configs/iterm2.json" "$HOME" <<'PYEOF'
import json, plistlib, pathlib, sys

config_path, home = sys.argv[1], sys.argv[2]

with open(config_path) as f:
    template = json.load(f)

# The installer writes one profile and identifies it by nothing but its name, so
# the name out of the template is what gets matched here.
name = template.get("Name")

plist_path = pathlib.Path(home) / "Library/Preferences/com.googlecode.iterm2.plist"

try:
    with open(plist_path, "rb") as f:
        prefs = plistlib.load(f)
except (FileNotFoundError, plistlib.InvalidFileException):
    print("No iTerm2 preferences found. Nothing to clear.")
    raise SystemExit(0)

profiles = prefs.get("New Bookmarks") or []
ours = [p for p in profiles if p.get("Name") == name]

if not ours:
    print("No Omakma iTerm2 profile found. Nothing to clear.")
    raise SystemExit(0)

kept = [p for p in profiles if p.get("Name") != name]
our_guids = set()
for profile in ours:
    if profile.get("Guid"):
        our_guids.add(profile["Guid"])

if kept:
    prefs["New Bookmarks"] = kept
else:
    # An empty list would leave iTerm2 with no profile at all. Dropping the key
    # lets it rebuild its own default instead.
    prefs.pop("New Bookmarks", None)

if prefs.get("Default Bookmark Guid") in our_guids:
    prefs.pop("Default Bookmark Guid", None)

# Appearance keys the installer sets. Removed only while they still hold the
# values it wrote, so a change the user made afterwards is left alone. These are
# hardcoded in install/desktop/app-iterm2.sh too; keep the two in step.
for key, installed in (("TabStyleWithAutomaticOption", 5), ("StatusBarPosition", 1)):
    if prefs.get(key) == installed:
        prefs.pop(key, None)

with open(plist_path, "wb") as f:
    plistlib.dump(prefs, f)

print("Cleared Omakma's iTerm2 profile and the appearance settings it wrote.")
print("The profiles you had before Omakma was installed cannot be brought back:")
print("the installer replaced them outright and took no backup.")
PYEOF
fi
