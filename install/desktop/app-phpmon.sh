if [ ! -d /Applications/PHP\ Monitor.app ]; then
  brew tap nicoverbruggen/homebrew-cask
  brew tap shivammathur/php
  brew install --cask phpmon
fi
