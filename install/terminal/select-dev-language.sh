# Install default programming languages
if [[ -n "${OMAKMA_FIRST_RUN_LANGUAGES}" ]]; then
  languages=$OMAKMA_FIRST_RUN_LANGUAGES
else
  AVAILABLE_LANGUAGES=("PHP" "Ruby on Rails" "Node.js" "Go" "Python" "Rust")
  languages=$(gum choose "${AVAILABLE_LANGUAGES[@]}" --no-limit --height 10 --header "Select programming languages")
fi

if [[ -n "$languages" ]]; then
  for language in $languages; do
    case $language in
    PHP)
      if ! command -v php &> /dev/null; then
        brew install php
        brew services start php
      fi
      if ! command -v composer &> /dev/null; then
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        php composer-setup.php --quiet
        sudo mkdir -p /usr/local/bin
        sudo mv composer.phar /usr/local/bin/composer
        rm composer-setup.php
      fi
      if ! command -v valet &> /dev/null; then
        composer global require laravel/valet
        valet install
        valet trust
      fi
      ;;
    Ruby)
      mise use --global ruby@3.3
      ;;
    Node.js)
      mise use --global node@lts
      ;;
    Go)
      mise use --global go@latest
      ;;
    Python)
      mise use --global python@latest
      ;;
    Rust)
      bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)" -- -y
      ;;
    esac
  done
fi
