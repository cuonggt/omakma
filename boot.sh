#!/bin/bash

ascii_art='
 ██████╗ ███╗   ███╗ █████╗ ██╗  ██╗███╗   ███╗ █████╗
██╔═══██╗████╗ ████║██╔══██╗██║ ██╔╝████╗ ████║██╔══██╗
██║   ██║██╔████╔██║███████║█████╔╝ ██╔████╔██║███████║
██║   ██║██║╚██╔╝██║██╔══██║██╔═██╗ ██║╚██╔╝██║██╔══██║
╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██╗██║ ╚═╝ ██║██║  ██║
 ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝
'

# The steps below are functions so they can be exercised. boot.sh is fetched and
# run before the repository exists, so unlike install/pin-to-release.sh they
# cannot live inside it. Sourcing this file with $OMAKMA_BOOT_DEFINE_ONLY set
# defines them and runs nothing, which is how test/boot-steps.sh drives them.
#
# The usual "am I being sourced" check is no help here: `bash < <(curl ...)`
# feeds the script in on stdin, so $0 is bash and BASH_SOURCE is empty.

OMAKMA_CLONE_URL="${OMAKMA_CLONE_URL:-https://github.com/cuonggt/omakma.git}"
OMAKMA_CLONE_PATH="${OMAKMA_CLONE_PATH:-$HOME/.local/share/omakma}"

# install_xcode_clt
# Install the Command Line Tools unless they are already there. Non-zero when
# they cannot be found in the software update list, which is fatal: nothing else
# can be built without them.
install_xcode_clt() {
  if xcode-select -p &>/dev/null; then
    echo -e "\nXcode Command Line Tools already installed."

    return 0
  fi

  echo -e "\nInstalling Xcode Command Line Tools..."
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

  local label
  label=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')

  if [ -z "$label" ]; then
    echo -e "\nCould not find Command Line Tools in software update list."

    return 1
  fi

  sudo softwareupdate --install "$label" --verbose &&
    sudo xcode-select --switch /Library/Developer/CommandLineTools
}

# clone_omakma
# Replace any previous checkout with a fresh clone.
clone_omakma() {
  echo -e "\nCloning Omakma..."
  rm -rf "$OMAKMA_CLONE_PATH"

  git clone "$OMAKMA_CLONE_URL" "$OMAKMA_CLONE_PATH" >/dev/null
}

if [ -n "$OMAKMA_BOOT_DEFINE_ONLY" ]; then
  return 0 2>/dev/null || exit 0
fi

clear
echo -e "\n$ascii_art"
echo -e "\n=> Omakma is for fresh macOS Sonoma 14.5 and newer installations only!"

install_xcode_clt || exit 1

# Guarded, where it was not before: boot.sh has no `set -e`, so a failed clone
# used to carry on and source two paths that were not there, reporting the
# missing files rather than the clone that never happened.
clone_omakma || exit 1

# Pick the version to install: the most recent release by default, master or
# any other ref through $OMAKMA_REF.
source "$OMAKMA_CLONE_PATH/install/pin-to-release.sh" "$OMAKMA_CLONE_PATH"

echo -e "\nInstallation starting..."
source "$OMAKMA_CLONE_PATH/install.sh"
