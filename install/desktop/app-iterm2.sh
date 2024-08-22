if [ ! -d /Applications/iTerm.app ]; then
  brew install --cask iterm2
fi

cp $HOME/.local/share/omakma/configs/iterm2.json $HOME/Library/Application\ Support/iTerm2/DynamicProfiles/omakma.json
defaults write com.googlecode.iterm2.plist "Default Bookmark Guid" -string 5D7D59C7-B2AA-40B4-ACE7-3052E6456A50
plutil -convert xml1 $HOME/Library/Preferences/com.googlecode.iterm2.plist
