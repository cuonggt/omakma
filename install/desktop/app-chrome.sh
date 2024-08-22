if [ ! -d /Applications/Google\ Chrome.app ]; then
  cd /tmp
  wget -O googlechrome.dmg 'https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg'
  VOLUME=$(hdiutil attach -nobrowse 'googlechrome.dmg' |
    tail -n1 | cut -f3-; exit ${PIPESTATUS[0]}) &&
  (rsync -a "$VOLUME"/*.app /Applications/; SYNCED=$?
    (hdiutil detach -force -quiet "$VOLUME" || exit $?) && exit "$SYNCED")
  rm googlechrome.dmg
  cd -
fi
