# PHP Monitor needs its own tap, plus shivammathur/php for the PHP versions it
# manages, so this cannot go through app_install. Both taps are third-party and
# can fail on their own, so a failure in any step is recorded once and the
# install carries on.
if ! app_installed "PHP Monitor.app"; then
  if ! {
    brew tap nicoverbruggen/homebrew-cask &&
      brew tap shivammathur/php &&
      brew install --cask phpmon
  }; then
    install_unavailable phpmon
  fi
fi
