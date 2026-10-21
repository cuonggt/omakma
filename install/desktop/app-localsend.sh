# LocalSend ships from its own tap rather than homebrew-core, so this cannot go
# through brew_app_install. The tap is third-party and can fail on its own --
# renamed, removed, or untrusted -- so a failure in either step is recorded once
# and the install carries on.
if ! app_installed "LocalSend.app"; then
  if ! { brew tap localsend/localsend && brew install localsend; }; then
    install_unavailable localsend
  fi
fi
