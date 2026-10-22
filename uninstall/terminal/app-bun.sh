brew_app_uninstall oven-sh/bun/bun || return 1 2>/dev/null || exit 1

untap_if_unused oven-sh/bun
