# Homebrew asks before loading formulae or casks from a tap it does not trust,
# which stops an install that is otherwise unattended. Trust the taps Omakma
# itself installs from, and only those: anything else already on the machine is
# the user's own business.
#
# Keep this list in step with the installers that tap:
#   localsend/localsend        install/desktop/app-localsend.sh
#   nicoverbruggen/cask        install/desktop/app-phpmon.sh
#   shivammathur/php           install/desktop/app-phpmon.sh
#   jesseduffield/lazydocker   install/terminal/app-lazydocker.sh
#   oven-sh/bun                install/terminal/app-bun.sh

# `brew trust` is recent. An older Homebrew has no trust prompt to satisfy, so
# there is nothing to do and nothing to warn about.
if brew trust --help &>/dev/null; then
  brew trust --taps \
    localsend/localsend \
    nicoverbruggen/cask \
    shivammathur/php \
    jesseduffield/lazydocker \
    oven-sh/bun ||
    echo "Could not trust Omakma's Homebrew taps; Homebrew may ask before installing from them."
fi
