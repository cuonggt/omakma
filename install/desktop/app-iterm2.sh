if [[ ! -d /Applications/iTerm.app ]]; then
  brew install --cask iterm2
fi

ITERM2_PROFILE_GUID=$(uuidgen)

# Build the profile from the config template
python3 - "$OMAKMA_PATH/configs/iterm2.json" "$ITERM2_PROFILE_GUID" "$HOME" <<'PYEOF'
import json, plistlib, sys, pathlib

config_path = sys.argv[1]
guid = sys.argv[2]
home = sys.argv[3]

with open(config_path) as f:
    data = json.load(f)

profile = data["Profiles"][0]
profile["Guid"] = guid
profile["Working Directory"] = home
profile["Default Bookmark"] = "Yes"
if "Tags" in profile:
    del profile["Tags"]

plist_path = pathlib.Path(home) / "Library/Preferences/com.googlecode.iterm2.plist"

try:
    with open(plist_path, "rb") as f:
        prefs = plistlib.load(f)
except (FileNotFoundError, plistlib.InvalidFileException):
    prefs = {}

bookmarks = prefs.get("New Bookmarks", [])
bookmarks.append(profile)
prefs["New Bookmarks"] = bookmarks
prefs["Default Bookmark Guid"] = guid
prefs["TabStyleWithAutomaticOption"] = 5  # Minimal theme
prefs["StatusBarPosition"] = 1  # Bottom

with open(plist_path, "wb") as f:
    plistlib.dump(prefs, f)
PYEOF
