# Install default programming languages
if [[ -n "${OMAKMA_FIRST_RUN_LANGUAGES+set}" ]]; then
  languages=$OMAKMA_FIRST_RUN_LANGUAGES
else
  AVAILABLE_LANGUAGES=("PHP" "Ruby on Rails" "Node.js" "Go" "Python" "Rust")
  languages=$(gum choose "${AVAILABLE_LANGUAGES[@]}" --no-limit --height 10 --header "Select programming languages")
fi

if [[ -n "$languages" ]]; then
  while IFS= read -r language; do
    # Ruby, Node, Go and Python all come through mise, so there is nothing to
    # try for them if mise itself did not install.
    case "$language" in
    "Ruby on Rails" | Node.js | Go | Python)
      if ! command -v mise &> /dev/null; then
        echo "Skipping $language: mise is not available."
        continue
      fi
      ;;
    esac

    case "$language" in
    PHP)
      if ! command -v php &> /dev/null; then
        if brew install php; then
          brew services start php
        else
          install_unavailable php
        fi
      fi

      # Composer and Valet are PHP programs. Without PHP they would fail one
      # after another, so skip them rather than taking the install down.
      if command -v php &> /dev/null; then
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
      fi
      ;;
    "Ruby on Rails")
      mise use --global ruby@latest
      mise x ruby -- gem install rails --no-document
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
      # Fetched to a file first: `bash -c "$(curl ...)"` turns a failed download
      # into `bash -c ""`, which succeeds and installs nothing.
      RUSTUP_INSTALLER=$(mktemp)

      if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$RUSTUP_INSTALLER"; then
        bash "$RUSTUP_INSTALLER" -y || download_failed Rust
      else
        download_failed Rust
      fi

      rm -f "$RUSTUP_INSTALLER"
      ;;
    esac
  done <<< "$languages"
fi
