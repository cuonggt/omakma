# LocalSend ships from its own tap rather than homebrew-core.
if ! app_installed "LocalSend.app"; then
  brew tap localsend/localsend
  brew install localsend
fi
