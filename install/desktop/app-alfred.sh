if [ ! -d /Applications/Alfred\ 5.app ]; then
  cd /tmp
  wget -O alfred.dmg 'https://cachefly.alfredapp.com/Alfred_5.5_2257.dmg'
  VOLUME=$(hdiutil attach -nobrowse 'alfred.dmg' |
    tail -n1 | cut -f3-; exit ${PIPESTATUS[0]}) &&
  (rsync -a "$VOLUME"/*.app /Applications/; SYNCED=$?
    (hdiutil detach -force -quiet "$VOLUME" || exit $?) && exit "$SYNCED")
  rm alfred.dmg
  cd -
fi
