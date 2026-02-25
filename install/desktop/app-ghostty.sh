if [ ! -d /Applications/Ghostty.app ]; then
  brew install --cask ghostty
fi

mkdir -p "$HOME/.config/ghostty/themes"
cp "$OMAKMA_PATH/configs/ghostty/config" "$HOME/.config/ghostty/config"
cp "$OMAKMA_PATH/configs/ghostty/themes/"* "$HOME/.config/ghostty/themes/"
