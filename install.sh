# Exit immediately if a command exits with a non-zero status
set -e

# Give people a chance to retry running the installation
trap 'echo "Omakma installation failed! You can retry by running: source ~/.local/share/omakma/install.sh"' ERR

# Set OMAKMA_PATH early so all sourced scripts can use it
export OMAKMA_PATH="$HOME/.local/share/omakma"

# Reusable installer helpers (app_install, copy_config, ...)
source "$OMAKMA_PATH/defaults/bash/functions"

# Check the macOS version and abort if incompatible
source "$OMAKMA_PATH/install/check-version.sh"

# Check for Homebrew and install if we don't have it
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export HOMEBREW_NO_INSTALL_FROM_API=1

sudo chown -R "$(whoami)" ~/Library/Caches/Homebrew
chmod -R u+rwX ~/Library/Caches/Homebrew

# Update Homebrew recipes
brew update

# Trust the taps Omakma installs from, so Homebrew does not stop to ask
source "$OMAKMA_PATH/install/trust-taps.sh"

# Terminals derive LANG from the system Region, and a Region with no matching
# UTF-8 locale (en_VN, say) leaves LC_CTYPE on the non-UTF-8 "C" locale. Set
# the Region only: Preferred Languages are the user's own, and overwriting
# them drops whichever languages they read macOS in.
defaults write NSGlobalDomain AppleLocale -string "en_US"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

echo "Get ready to make a few choices..."
source "$OMAKMA_PATH/install/terminal/required/app-gum.sh" >/dev/null
source "$OMAKMA_PATH/install/preflight.sh"
source "$OMAKMA_PATH/install/first-run-choices.sh"

echo "Installing terminal and desktop tools..."

# Install terminal tools
source "$OMAKMA_PATH/install/terminal.sh"

# Install desktop tools and tweaks
source "$OMAKMA_PATH/install/desktop.sh"
