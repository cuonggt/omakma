app_uninstall phpmon || return 1 2>/dev/null || exit 1

# Only PHP Monitor's own tap. shivammathur/php stays: `omakma install` installs
# PHP versions from it, so removing one app is no reason to take it away.
untap_if_unused nicoverbruggen/cask
