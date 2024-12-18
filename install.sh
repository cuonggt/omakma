# Exit immediately if a command exits with a non-zero status
set -e

# Check the macOS version and abort if incompatible
source $HOME/.local/share/omakma/install/check-version.sh

# Check for Homebrew and install if we don't have it
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export HOMEBREW_NO_INSTALL_FROM_API=1

# Update Homebrew recipes
brew update

echo "Get ready to make a few choices..."
source $HOME/.local/share/omakma/install/terminal/required/app-gum.sh >/dev/null
source $HOME/.local/share/omakma/install/first-run-choices.sh

echo "Installing terminal and desktop tools..."

# Install terminal tools
source $HOME/.local/share/omakma/install/terminal.sh

# Install desktop tools and tweaks
source $HOME/.local/share/omakma/install/desktop.sh
