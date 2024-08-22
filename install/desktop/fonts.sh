mkdir -p $HOME/Library/Fonts

if ! $(fc-list | grep -i "JetBrainsMono" >/dev/null); then
  cd /tmp
  wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip JetBrainsMono.zip -d JetBrainsMono
  cp JetBrainsMono/*.ttf $HOME/Library/Fonts
  rm -rf JetBrainsMono.zip JetBrainsMono

  fc-cache
  cd -
fi
