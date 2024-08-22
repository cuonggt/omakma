if [ ! -d /Applications/DBngin.app ]; then
  cd /tmp
  wget -O dbngin.dmg 'https://dbngin.com/release/osx/dbngin_latest'
  VOLUME=$(hdiutil attach -nobrowse 'dbngin.dmg' |
    tail -n1 | cut -f3-; exit ${PIPESTATUS[0]}) &&
  (rsync -a "$VOLUME"/*.app /Applications/; SYNCED=$?
    (hdiutil detach -force -quiet "$VOLUME" || exit $?) && exit "$SYNCED")
  rm dbngin.dmg
  cd -
fi
