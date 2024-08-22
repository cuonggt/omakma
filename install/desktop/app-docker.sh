if [ ! -d /Applications/Docker.app ]; then
  cd /tmp
  wget -O Docker.dmg 'https://desktop.docker.com/mac/main/arm64/Docker.dmg'
  sudo hdiutil attach Docker.dmg
  sudo /Volumes/Docker/Docker.app/Contents/MacOS/install
  sudo hdiutil detach /Volumes/Docker
  rm Docker.dmg
  cd -
fi
