app_install iterm2 "iTerm.app"

# Clean up any old dynamic profile
rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/omakma.json"

ITERM2_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

# iTerm2 holds its preferences in memory and writes them back when it quits, so
# anything written here underneath a running iTerm2 is silently lost. That is
# easy to hit from `omakma install`, since the terminal running it may well be
# iTerm2 itself.
if pgrep -qx iTerm2; then
  echo "iTerm2 is running and would overwrite its preferences when it quits."
  echo "Quit iTerm2, then run: omakma install"
else
  # Omakma adds a profile to whatever is already there. It used to assign
  # New Bookmarks a one-item list, which threw away every profile the user had,
  # with no backup to recover them from.
  backup_config "$ITERM2_PLIST"

  ITERM2_PROFILE_GUID=$(uuidgen)

  # Build the profile from the config template
  python3 - "$OMAKMA_PATH/configs/iterm2.json" "$ITERM2_PROFILE_GUID" "$HOME" <<'PYEOF'
import json, plistlib, sys, pathlib

config_path = sys.argv[1]
fallback_guid = sys.argv[2]
home = sys.argv[3]

with open(config_path) as f:
    profile = json.load(f)

name = profile.get("Name")

plist_path = pathlib.Path(home) / "Library/Preferences/com.googlecode.iterm2.plist"

try:
    with open(plist_path, "rb") as f:
        prefs = plistlib.load(f)
except (FileNotFoundError, plistlib.InvalidFileException):
    prefs = {}

existing = prefs.get("New Bookmarks") or []
ours = [p for p in existing if p.get("Name") == name]
theirs = [p for p in existing if p.get("Name") != name]

# Re-use the guid from a previous run rather than minting a new one, so
# anything iTerm2 has bound to that profile keeps working.
guid = fallback_guid
for previous in ours:
    if previous.get("Guid"):
        guid = previous["Guid"]
        break

profile["Guid"] = guid
profile["Working Directory"] = home
profile["Default Bookmark"] = "Yes"

# One Omakma profile, alongside the user's, however many times this is re-run.
prefs["New Bookmarks"] = theirs + [profile]

# Claim the default profile on a first install. On a re-run, only take it back
# if it is still pointing at Omakma's own profile -- a default the user has
# since chosen themselves is theirs to keep. Same for the appearance keys:
# uninstall/desktop/app-iterm2.sh clears these two on the same terms, so keep
# the values in step.
our_guids = set()
for previous in ours:
    if previous.get("Guid"):
        our_guids.add(previous["Guid"])

if not ours or prefs.get("Default Bookmark Guid") in our_guids:
    prefs["Default Bookmark Guid"] = guid

for key, value in (("TabStyleWithAutomaticOption", 5), ("StatusBarPosition", 1)):
    if not ours or prefs.get(key) == value:
        prefs[key] = value

# Always there on a real account, but writing into a directory that does not
# exist fails rather than creating it.
plist_path.parent.mkdir(parents=True, exist_ok=True)

with open(plist_path, "wb") as f:
    plistlib.dump(prefs, f)

if theirs:
    print("Added the Omakma iTerm2 profile alongside your %d existing profile(s)." % len(theirs))
PYEOF
fi
