if [ ! -d /Applications/iTerm.app ]; then
  brew install --cask iterm2
fi

mkdir -p $HOME/Library/Application\ Support/iTerm2/DynamicProfiles
cp $HOME/.local/share/omakma/configs/iterm2.json $HOME/Library/Application\ Support/iTerm2/DynamicProfiles/omakma.json
ITERM2_DEFAULT_PROFILE_GUID=$(uuidgen)
gsed -i "s/\"Guid\" : \".*\"/\"Guid\" : \"$ITERM2_DEFAULT_PROFILE_GUID\"/g" $HOME/Library/Application\ Support/iTerm2/DynamicProfiles/omakma.json
defaults write com.googlecode.iterm2.plist "Default Bookmark Guid" -string $ITERM2_DEFAULT_PROFILE_GUID
plutil -convert xml1 $HOME/Library/Preferences/com.googlecode.iterm2.plist
# mkdir -p $HOME/Library/Application\ Support/iTerm2/Scripts/AutoLaunch
