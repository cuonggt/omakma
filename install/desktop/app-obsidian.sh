if [ ! -d /Applications/Obsidian.app ]; then
  cd /tmp
  wget -O obsidian.dmg 'https://github.com/obsidianmd/obsidian-releases/releases/download/v1.6.7/Obsidian-1.6.7.dmg'
  VOLUME=$(hdiutil attach -nobrowse 'obsidian.dmg' |
    tail -n1 | cut -f3-; exit ${PIPESTATUS[0]}) &&
  (rsync -a "$VOLUME"/*.app /Applications/; SYNCED=$?
    (hdiutil detach -force -quiet "$VOLUME" || exit $?) && exit "$SYNCED")
  rm obsidian.dmg
  cd -
fi
