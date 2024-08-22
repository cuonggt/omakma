OPTIONAL_APPS=("Zed" "Dropbox" "Pritunl" "Xmind" "Brave")
DEFAULT_OPTIONAL_APPS="Zed","Dropbox","Pritunl","Xmind"
export OMAKMA_FIRST_RUN_OPTIONAL_APPS=$(gum choose "${OPTIONAL_APPS[@]}" --no-limit --selected $DEFAULT_OPTIONAL_APPS --height 7 --header "Select optional apps" | tr ' ' '-')

AVAILABLE_LANGUAGES=("PHP" "Ruby on Rails" "Node.js" "Go" "Python" "Rust")
SELECTED_LANGUAGES="PHP","Ruby on Rails","Node.js"
export OMAKMA_FIRST_RUN_LANGUAGES=$(gum choose "${AVAILABLE_LANGUAGES[@]}" --no-limit --selected "$SELECTED_LANGUAGES" --height 10 --header "Select programming languages")

AVAILABLE_DBS=("MySQL" "Redis" "PostgreSQL")
SELECTED_DBS=""
export OMAKMA_FIRST_RUN_DBS=$(gum choose "${AVAILABLE_DBS[@]}" --no-limit --selected "$SELECTED_DBS" --height 5 --header "Select databases")
