# Exit immediately if a command exits with a non-zero status
set -e

# Give people a chance to retry running the installation
trap 'echo "Omakma installation failed! You can retry by running: source ~/.local/share/omakma/install.sh"' ERR

# Set OMAKMA_PATH early so all sourced scripts can use it
export OMAKMA_PATH="$HOME/.local/share/omakma"

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

echo "Get ready to make a few choices..."
source "$OMAKMA_PATH/install/terminal/required/app-gum.sh" >/dev/null
source "$OMAKMA_PATH/install/first-run-choices.sh"

echo "Installing terminal and desktop tools..."

# Install terminal tools
source "$OMAKMA_PATH/install/terminal.sh"

# Install desktop tools and tweaks
source "$OMAKMA_PATH/install/desktop.sh"
