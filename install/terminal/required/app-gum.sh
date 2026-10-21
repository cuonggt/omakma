# Deliberately not brew_install. gum drives the first-run choices and both the
# install and uninstall menus, so there is nothing left to carry on with if it
# is missing: this is the one package whose absence should still take the run
# down rather than being recorded and skipped.
brew list gum &>/dev/null || brew install gum
