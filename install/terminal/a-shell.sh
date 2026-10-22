# Check for Oh My Zsh and install if we don't have it
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  # Fetched to a file first and then run. `sh -c "$(curl ...)"` turns a failed
  # download into `sh -c ""`, which succeeds and installs nothing, so the
  # install would carry on believing Oh My Zsh was there.
  OHMYZSH_INSTALLER=$(mktemp)

  if curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$OHMYZSH_INSTALLER"; then
    sh "$OHMYZSH_INSTALLER" "" --unattended || download_failed "Oh My Zsh"
  else
    download_failed "Oh My Zsh"
  fi

  rm -f "$OHMYZSH_INSTALLER"
fi

# The plugins live inside Oh My Zsh, so there is nowhere to put them if that did
# not install. Cloning into a missing .oh-my-zsh is what used to end the run.
if [ -d "$HOME/.oh-my-zsh" ]; then
  clone_if_missing "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" https://github.com/zsh-users/zsh-autosuggestions
  clone_if_missing "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" https://github.com/zsh-users/zsh-syntax-highlighting.git
  clone_if_missing "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-z" https://github.com/agkozak/zsh-z
fi

# Configure the zsh shell using Omakma defaults since zsh became the default shell in macOS
copy_config "$OMAKMA_PATH/configs/zshrc" "$HOME/.zshrc"

# Configure the bash shell using Omakma defaults
copy_config "$OMAKMA_PATH/configs/bashrc" "$HOME/.bashrc"

touch "$HOME/.hushlogin"

# Load the PATH for use later in the installers
source "$OMAKMA_PATH/defaults/bash/shell"

# Configure the inputrc using Omakma defaults
copy_config "$OMAKMA_PATH/configs/inputrc" "$HOME/.inputrc"
