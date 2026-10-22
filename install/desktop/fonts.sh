mkdir -p "$HOME/Library/Fonts"

if ! fc-list | grep -qi "JetBrainsMono"; then
  if wget -q -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
    unzip -o /tmp/JetBrainsMono.zip -d /tmp/JetBrainsMono
    cp /tmp/JetBrainsMono/*.ttf "$HOME/Library/Fonts"
    rm -rf /tmp/JetBrainsMono.zip /tmp/JetBrainsMono
    fc-cache
  else
    download_failed "the JetBrainsMono font"
  fi
fi
