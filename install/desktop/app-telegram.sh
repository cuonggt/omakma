if [ ! -d /Applications/Telegram.app ]; then
  cd /tmp
  wget -O telegram.dmg 'https://telegram.org/dl/desktop/mac'
  VOLUME=$(hdiutil attach -nobrowse 'telegram.dmg' |
    tail -n1 | cut -f3-; exit ${PIPESTATUS[0]}) &&
  (rsync -a "$VOLUME"/*.app /Applications/; SYNCED=$?
    (hdiutil detach -force -quiet "$VOLUME" || exit $?) && exit "$SYNCED")
  rm telegram.dmg
  cd -
fi
