UNINSTALLER_FILE=$(gum file "$OMAKMA_PATH/uninstall")

[[ -n "$UNINSTALLER_FILE" ]] &&
  gum confirm "Run uninstaller?" &&
  source "$UNINSTALLER_FILE" &&
  gum spin --spinner globe --title "Uninstall completed!" -- sleep 3

clear
source "$OMAKMA_PATH/bin/omakma"
