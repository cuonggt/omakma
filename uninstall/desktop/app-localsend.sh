brew_app_uninstall localsend || return 1 2>/dev/null || exit 1

untap_if_unused localsend/localsend
