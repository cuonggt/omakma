# Wipe all (default) app icons from the Dock
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array

defaults write com.apple.dock show-recents -bool false

killall Dock
