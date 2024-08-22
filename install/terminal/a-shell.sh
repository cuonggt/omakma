# Check for Oh My Zsh and install if we don't have it
if [ ! -d $HOME/.oh-my-zsh ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-z" ] && git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z

# Configure the zsh shell using Omakma defaults since zsh became the default shell in macOS
[ -f "$HOME/.zshrc" ] && mv $HOME/.zshrc $HOME/.zshrc.bak
cp $HOME/.local/share/omakma/configs/zshrc $HOME/.zshrc

# Configure the bash shell using Omakma defaults
[ -f "$HOME/.bashrc" ] && mv $HOME/.bashrc $HOME/.bashrc.bak
cp $HOME/.local/share/omakma/configs/bashrc $HOME/.bashrc

touch $HOME/.hushlogin

# Load the PATH for use later in the installers
source $HOME/.local/share/omakma/defaults/bash/shell

[ -f "$HOME/.inputrc" ] && mv $HOME/.inputrc $HOME/.inputrc.bak
# Configure the inputrc using Omakma defaults
cp $HOME/.local/share/omakma/configs/inputrc $HOME/.inputrc
