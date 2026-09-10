if [ $# -eq 0 ]; then
  SUB=$(gum choose "Theme" "Font" "Install" "Uninstall" "Update" "Quit" --height 10 --header "" | tr '[:upper:]' '[:lower:]')
else
  SUB=$1
  shift
fi

[ -n "$SUB" ] && [ "$SUB" != "quit" ] && source "$OMAKMA_PATH/bin/omakma-sub/$SUB.sh" "$@"
