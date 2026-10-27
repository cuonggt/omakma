if ! app_installed "Recordly.app"; then
  if [[ "$(uname -m)" == "arm64" ]]; then
    DMG_NAME="Recordly-arm64.dmg"
  else
    DMG_NAME="Recordly-x64.dmg"
  fi

  TMP_DMG=$(mktemp -t recordly).dmg

  # Recordly comes from a third-party release rather than Homebrew, so a renamed
  # release or a network blip is more likely here than anywhere else -- and an
  # unguarded `curl -f` under set -e took the whole install with it.
  if curl -fsSL "https://github.com/webadderallorg/Recordly/releases/latest/download/$DMG_NAME" -o "$TMP_DMG"; then
    # The mount point comes from hdiutil rather than from searching all of
    # /Volumes, which could pick up a Recordly.app on some unrelated disk.
    RECORDLY_VOLUME=$(hdiutil attach -nobrowse -noverify "$TMP_DMG" | grep -o '/Volumes/.*' | tail -1)

    if [[ -n "$RECORDLY_VOLUME" ]]; then
      APP_SRC=$(find "$RECORDLY_VOLUME" -maxdepth 2 -name "Recordly.app" -print -quit 2>/dev/null)

      if [[ -n "$APP_SRC" ]]; then
        cp -R "$APP_SRC" /Applications/
        xattr -dr com.apple.quarantine /Applications/Recordly.app 2>/dev/null || true
      else
        setup_failed Recordly
      fi

      # Detached either way: the old version only unmounted when it found the
      # app, so a bad image stayed mounted.
      hdiutil detach -quiet "$RECORDLY_VOLUME"
    else
      setup_failed Recordly
    fi
  else
    download_failed Recordly
  fi

  rm -f "$TMP_DMG"
fi
