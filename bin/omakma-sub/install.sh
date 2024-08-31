CHOICES=(
  "Dev Language  Install programming language environment"
  "Dev Database  Install development database"
  "Brave         Chrome-based browser with built-in ad blocking"
  "Dropbox       Sync files across computers with ease"
  "Ollama        Run LLMs, like Meta's Llama3, locally"
  "PhpStorm      IntelliJ's commercial PHP editor"
  "Pritunl       OpenVPN client"
  "RubyMine      IntelliJ's commercial Ruby editor"
  "Spotify       Stream music from the world's most popular service"
  "Steam         Play games from Valve's store"
  "Xmind         Mind mapping software"
  "Zed           Fast all-purpose editor"
  "Zoom          Attend and host video chat meetings"
  "> All         Re-run any of the default installers"
  "<< Back       "
)

CHOICE=$(gum choose "${CHOICES[@]}" --height 19 --header "Install application")

if [[ "$CHOICE" == "<< Back"* ]] || [[ -z "$CHOICE" ]]; then
  # Don't install anything
  echo ""
elif [[ "$CHOICE" == "> All"* ]]; then
  INSTALLER_FILE=$(gum file $OMAKMA_PATH/install)

  [[ -n "$INSTALLER_FILE" ]] &&
    gum confirm "Run installer?" &&
    source $INSTALLER_FILE &&
    gum spin --spinner globe --title "Install completed!" -- sleep 3
else
  INSTALLER=$(echo "$CHOICE" | awk -F ' {2,}' '{print $1}' | tr '[:upper:]' '[:lower:]' | gsed 's/ /-/g')

  case "$INSTALLER" in
  "dev-language") INSTALLER_FILE="$OMAKMA_PATH/install/terminal/select-dev-language.sh" ;;
  "dev-database") INSTALLER_FILE="$OMAKMA_PATH/install/terminal/optional/select-dev-database.sh" ;;
  "ollama") INSTALLER_FILE="$OMAKMA_PATH/install/terminal/optional/app-ollama.sh" ;;
  *) INSTALLER_FILE="$OMAKMA_PATH/install/desktop/optional/app-$INSTALLER.sh" ;;
  esac

  source $INSTALLER_FILE && gum spin --spinner globe --title "Install completed!" -- sleep 3
fi

clear
source $OMAKMA_PATH/bin/omakma
