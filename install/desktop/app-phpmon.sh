# PHP Monitor needs its own tap, plus shivammathur/php for the PHP versions it manages.
if ! app_installed "PHP Monitor.app"; then
  brew tap nicoverbruggen/homebrew-cask
  brew tap shivammathur/php
  brew install --cask phpmon
fi
