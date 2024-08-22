if [ ! -d /Applications/TablePlus.app ]; then
  cd /tmp
  wget -O tableplus.dmg 'https://tableplus.com/release/osx/tableplus_latest'
  VOLUME=$(hdiutil attach -nobrowse 'tableplus.dmg' |
    tail -n1 | cut -f3-; exit ${PIPESTATUS[0]}) &&
  (rsync -a "$VOLUME"/*.app /Applications/; SYNCED=$?
    (hdiutil detach -force -quiet "$VOLUME" || exit $?) && exit "$SYNCED")
  rm tableplus.dmg
  cd -
fi
