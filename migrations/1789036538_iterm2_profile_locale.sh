# Older installs left iTerm2 deriving LANG from the system Region instead of
# pinning it, and some carry a leftover DynamicProfiles/omakma.json from an
# even earlier layout. Both leave iTerm2 sessions on a broken locale.
#
# configs/iterm2.json now pins the locale, but re-running app-iterm2.sh here
# would be wrong: it replaces *every* iTerm2 profile with Omakma's, so any
# profile the user has made would be lost. Patch just the locale keys onto
# Omakma's own profile instead.

if [[ ! -d /Applications/iTerm.app ]]; then
  echo "  iTerm2 is not installed. Nothing to do."
  # shellcheck disable=SC2317  # sourced normally, run directly when testing
  return 0 2>/dev/null || exit 0
fi

# Safe to remove whether or not iTerm2 is running: iTerm2 reads dynamic
# profiles from disk rather than caching them in its preferences.
rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/omakma.json"

# iTerm2 holds its preferences in memory and writes them back when it quits,
# so patching the plist underneath a running iTerm2 gets silently undone.
if pgrep -qx iTerm2; then
  echo "  iTerm2 is running and would overwrite this change when it quits."
  echo "  Quit iTerm2, then run: omakma update"
  # shellcheck disable=SC2317  # sourced normally, run directly when testing
  return 1 2>/dev/null || exit 1
fi

python3 - "$OMAKMA_PATH/configs/iterm2.json" "$HOME" <<'PYEOF'
import json, plistlib, pathlib, sys

config_path, home = sys.argv[1], sys.argv[2]

with open(config_path) as f:
    template = json.load(f)

# The template is the source of truth for what "correct" looks like.
locale_keys = {k: template[k] for k in ("Set Locale Vars", "Custom Locale", "Environment") if k in template}

plist_path = pathlib.Path(home) / "Library/Preferences/com.googlecode.iterm2.plist"

try:
    with open(plist_path, "rb") as f:
        prefs = plistlib.load(f)
except (FileNotFoundError, plistlib.InvalidFileException):
    print("  No iTerm2 preferences found. Nothing to do.")
    raise SystemExit(0)

profiles = [p for p in prefs.get("New Bookmarks") or [] if p.get("Name") == template.get("Name")]

if not profiles:
    print("  No Omakma iTerm2 profile found. Nothing to do.")
    raise SystemExit(0)

for profile in profiles:
    for key, value in locale_keys.items():
        if key == "Environment":
            environment = profile.get("Environment") or {}
            environment.update(value)
            profile["Environment"] = environment
        else:
            profile[key] = value

with open(plist_path, "wb") as f:
    plistlib.dump(prefs, f)

print("  Pinned the Omakma iTerm2 profile to %s." % locale_keys.get("Custom Locale", "the configured locale"))
PYEOF
