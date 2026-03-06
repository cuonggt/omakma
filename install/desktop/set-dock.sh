# Wipe all (default) app icons from the Dock
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array

defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock autohide -bool true

killall Dock
