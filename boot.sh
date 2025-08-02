#!/bin/bash

set -e

ascii_art=' ██████╗ ███╗   ███╗ █████╗ ██╗  ██╗██╗███╗   ███╗ █████╗
██╔═══██╗████╗ ████║██╔══██╗██║ ██╔╝██║████╗ ████║██╔══██╗
██║   ██║██╔████╔██║███████║█████╔╝ ██║██╔████╔██║███████║
██║   ██║██║╚██╔╝██║██╔══██║██╔═██╗ ██║██║╚██╔╝██║██╔══██║
╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██╗██║██║ ╚═╝ ██║██║  ██║
 ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝'

clear
echo -e "\n$ascii_art\n"
echo "=> Omakma is for fresh macOS Sonoma 14.5 installations only!"
echo -e "\nBegin installation (or abort with ctrl+c)..."

if xcode-select -p &>/dev/null; then
  echo -e "\nXcode Command Line Tools already installed."
else
  echo -e "\nInstalling Xcode Command Line Tools..."
  LABEL=$(softwareupdate --list | grep -E '\*.*Command Line Tools' | head -1 | awk -F"*" '{print $2}' | sed -e 's/^ *//')
  if [ -n "$LABEL" ]; then
    sudo softwareupdate --install "$LABEL" --verbose
    sudo xcode-select --switch /Library/Developer/CommandLineTools
  else
    echo -e "\nCould not find Command Line Tools in software update list."
    exit 1
  fi
fi

echo "\nCloning Omakma..."
rm -rf ~/.local/share/omakma
git clone https://github.com/cuonggt/omakma.git ~/.local/share/omakma >/dev/null
if [[ $OMAKMA_REF != "master" ]]; then
  cd ~/.local/share/omakma
  git fetch origin "${OMAKMA_REF:-stable}" && git checkout "${OMAKMA_REF:-stable}"
  cd -
fi

echo -e "\nInstallation starting..."
source ~/.local/share/omakma/install.sh
