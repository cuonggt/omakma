if ! app_installed "Recordly.app"; then
  if [[ "$(uname -m)" == "arm64" ]]; then
    DMG_NAME="Recordly-arm64.dmg"
  else
    DMG_NAME="Recordly-x64.dmg"
  fi

  TMP_DMG=$(mktemp -t recordly).dmg
  curl -fsSL "https://github.com/webadderallorg/Recordly/releases/latest/download/$DMG_NAME" -o "$TMP_DMG"

  hdiutil attach -nobrowse -quiet "$TMP_DMG"
  APP_SRC=$(find /Volumes -maxdepth 2 -name "Recordly.app" -print -quit 2>/dev/null)
  if [[ -n "$APP_SRC" ]]; then
    cp -R "$APP_SRC" /Applications/
    hdiutil detach -quiet "$(dirname "$APP_SRC")"
    xattr -dr com.apple.quarantine /Applications/Recordly.app 2>/dev/null || true
  fi
  rm -f "$TMP_DMG"
fi
