UNINSTALLER_FILE=$(gum file "$OMAKMA_PATH/uninstall")
UNINSTALL_RAN=false

if [[ -n "$UNINSTALLER_FILE" ]] && gum confirm "Run uninstaller?"; then
  source "$UNINSTALLER_FILE"
  UNINSTALL_RAN=true
fi

# "Uninstall completed!" used to fire whichever way it went: both brew helpers
# ended in `|| true` with stderr discarded, so an uninstaller always returned 0
# and the && chain that gated the spinner was never false. Say what actually
# happened -- and when something failed, skip the clear, which would wipe the
# only account of it.
if [ "${#OMAKMA_FAILED_UNINSTALLS[@]}" -gt 0 ]; then
  report_failed_uninstalls
else
  if [ "$UNINSTALL_RAN" = true ]; then
    gum spin --spinner globe --title "Uninstall completed!" -- sleep 3
  fi

  clear
fi

source "$OMAKMA_PATH/bin/omakma"
