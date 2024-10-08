OPTIONAL_APPS=("1111" "Dropbox" "Pritunl" "Xmind" "Zed")
DEFAULT_OPTIONAL_APPS="1111","Dropbox","Pritunl","Xmind","Zed"
export OMAKMA_FIRST_RUN_OPTIONAL_APPS=$(gum choose "${OPTIONAL_APPS[@]}" --no-limit --selected $DEFAULT_OPTIONAL_APPS --height 7 --header "Select optional apps" | tr ' ' '-')

AVAILABLE_LANGUAGES=("PHP" "Ruby on Rails" "Node.js" "Go" "Python" "Rust")
SELECTED_LANGUAGES="PHP","Ruby on Rails","Node.js","Go","Python"
export OMAKMA_FIRST_RUN_LANGUAGES=$(gum choose "${AVAILABLE_LANGUAGES[@]}" --no-limit --selected "$SELECTED_LANGUAGES" --height 10 --header "Select programming languages")
