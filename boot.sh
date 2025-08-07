#!/bin/bash

ascii_art='
 ██████╗ ███╗   ███╗ █████╗ ██╗  ██╗███╗   ███╗ █████╗
██╔═══██╗████╗ ████║██╔══██╗██║ ██╔╝████╗ ████║██╔══██╗
██║   ██║██╔████╔██║███████║█████╔╝ ██╔████╔██║███████║
██║   ██║██║╚██╔╝██║██╔══██║██╔═██╗ ██║╚██╔╝██║██╔══██║
╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██╗██║ ╚═╝ ██║██║  ██║
 ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝
'

clear
echo -e "\n$ascii_art"
echo -e "\n=> Omakma is for fresh macOS Sonoma 14.5 and newer installations only!"

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

echo -e "\nCloning Omakma..."
rm -rf ~/.local/share/omakma
git clone https://github.com/cuonggt/omakma.git ~/.local/share/omakma >/dev/null
if [[ $OMAKMA_REF != "master" ]]; then
  cd ~/.local/share/omakma
  git fetch origin "${OMAKMA_REF:-master}" && git checkout "${OMAKMA_REF:-master}"
  cd -
fi

echo -e "\nInstallation starting..."
source ~/.local/share/omakma/install.sh
