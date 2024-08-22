if [ ! -d /Applications/Brave\ Browser.app ]; then
  cd /tmp
  wget -O brave.dmg 'https://referrals.brave.com/latest/BRV010/Brave-Browser.dmg'
  VOLUME=$(hdiutil attach -nobrowse 'brave.dmg' |
    tail -n1 | cut -f3-; exit ${PIPESTATUS[0]}) &&
  (rsync -a "$VOLUME"/*.app /Applications/; SYNCED=$?
    (hdiutil detach -force -quiet "$VOLUME" || exit $?) && exit "$SYNCED")
  rm brave.dmg
  cd -
fi
