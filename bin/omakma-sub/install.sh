CHOICES=(
  "Dev Language  Install programming language environment"
  "Dev Database  Install development database"
  "Dropbox       Sync files across computers with ease"
  "Ollama        Run LLMs, like Meta's Llama3, locally"
  "OpenKey       Bộ gõ tiếng Việt miễn phí mã nguồn mở"
  "Pritunl       OpenVPN client"
  "Spotify       Stream music from the world's most popular service"
  "Steam         Play games from Valve's store"
  "Xmind         Mind mapping software"
  "Zoom          Attend and host video chat meetings"
  "> All         Re-run any of the default installers"
  "<< Back       "
)

CHOICE=$(gum choose "${CHOICES[@]}" --height 19 --header "Install application")
INSTALL_RAN=false

if [[ "$CHOICE" == "<< Back"* ]] || [[ -z "$CHOICE" ]]; then
  # Don't install anything
  echo ""
elif [[ "$CHOICE" == "> All"* ]]; then
  INSTALLER_FILE=$(gum file "$OMAKMA_PATH/install")

  if [[ -n "$INSTALLER_FILE" ]] && gum confirm "Run installer?"; then
    source "$INSTALLER_FILE"
    INSTALL_RAN=true
  fi
else
  # tr rather than gsed for the slug: gnu-sed is installable but skippable, and
  # a missing one here would blank the choice and source a path that is not
  # there.
  INSTALLER=$(echo "$CHOICE" | awk -F ' {2,}' '{print $1}' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

  case "$INSTALLER" in
  "dev-language") INSTALLER_FILE="$OMAKMA_PATH/install/terminal/select-dev-language.sh" ;;
  "dev-database") INSTALLER_FILE="$OMAKMA_PATH/install/terminal/select-dev-database.sh" ;;
  "ollama") INSTALLER_FILE="$OMAKMA_PATH/install/terminal/optional/app-ollama.sh" ;;
  *) INSTALLER_FILE="$OMAKMA_PATH/install/desktop/optional/app-$INSTALLER.sh" ;;
  esac

  source "$INSTALLER_FILE"
  INSTALL_RAN=true
fi

# "Install completed!" used to fire whichever way it went. The install helpers
# return 0 when Homebrew will not hand a package over, or a download fails, so
# the && chain that gated the spinner never saw a failure -- and the clear below
# then wiped the only account of it. Say what actually happened, and when
# something was skipped keep it on screen.
if [ "${#OMAKMA_FAILED_INSTALLS[@]}" -gt 0 ]; then
  report_failed_installs
else
  if [ "$INSTALL_RAN" = true ]; then
    gum spin --spinner globe --title "Install completed!" -- sleep 3
  fi

  clear
fi

source "$OMAKMA_PATH/bin/omakma"
