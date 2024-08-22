if [ ! -d /Applications/OpenKey.app ]; then
  cd /tmp
  wget -O openkey.dmg 'https://github.com/tuyenvm/OpenKey/releases/download/2.0.5/OpenKey2.0.5.dmg'
  VOLUME=$(hdiutil attach -nobrowse 'openkey.dmg' |
    tail -n1 | cut -f3-; exit ${PIPESTATUS[0]}) &&
  (rsync -a "$VOLUME"/*.app /Applications/; SYNCED=$?
    (hdiutil detach -force -quiet "$VOLUME" || exit $?) && exit "$SYNCED")
  rm openkey.dmg
  cd -
fi
