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
          # Downloaded to a temp directory and checked before it is run.
          # `php -r "copy(...)"` exits 0 when the download fails and writes no
          # file, so the line after it ran php against a file that was not
          # there -- which, under set -e, ended the install at the retry
          # message before install/desktop.sh had run at all. Since PHP is
          # preselected, that was every default install on a bad connection.
          # The checksum is published on a different host to the installer,
          # which is what Composer publishes it for. Hashed with php rather
          # than shasum: php is already known to be here, it is what Composer's
          # own instructions use, and shasum is missing on the Linux runner the
          # tests run on.
          COMPOSER_TMP=$(mktemp -d)

          if ! curl --proto '=https' --tlsv1.2 -sSf https://getcomposer.org/installer -o "$COMPOSER_TMP/installer" ||
            ! curl --proto '=https' --tlsv1.2 -sSf https://composer.github.io/installer.sig -o "$COMPOSER_TMP/installer.sig"; then
            download_failed Composer
          else
            # shellcheck disable=SC2016 # $argv is PHP's, so the quotes stay single
            if ! COMPOSER_HASH=$(php -r 'echo hash_file("sha384", $argv[1]);' -- "$COMPOSER_TMP/installer"); then
              setup_failed Composer
            elif [ "$COMPOSER_HASH" != "$(cat "$COMPOSER_TMP/installer.sig")" ]; then
              echo "The Composer installer did not match its published checksum, so it was not run."
              download_failed Composer
            # --install-dir and --filename keep the phar out of whatever
            # directory the install was started from. Nothing here ever cd's, so
            # the old version wrote composer-setup.php and composer.phar into
            # $PWD -- the user's home, for the documented one-liner -- and left
            # the setup script sitting there whenever a later step failed.
            elif ! php "$COMPOSER_TMP/installer" --quiet --install-dir="$COMPOSER_TMP" --filename=composer; then
              setup_failed Composer
            elif ! sudo mkdir -p /usr/local/bin ||
              ! sudo mv "$COMPOSER_TMP/composer" /usr/local/bin/composer; then
              setup_failed Composer
            fi
          fi

          rm -rf "$COMPOSER_TMP"
        fi

        # Valet comes from Composer rather than Homebrew, into
        # ~/.composer/vendor/bin. Look for it again afterwards rather than
        # assuming the require worked: a failed one left `valet install` to run
        # as a command that was not there, and took the install with it.
        if ! command -v valet &> /dev/null; then
          if ! command -v composer &> /dev/null; then
            echo "Skipping Valet: Composer is not available."
          elif ! composer global require laravel/valet; then
            download_failed Valet
          elif ! command -v valet &> /dev/null; then
            echo "Valet installed, but is not on PATH, so it was not set up."
            setup_failed Valet
          elif ! valet install; then
            setup_failed Valet
          else
            valet trust || echo "Could not run valet trust, so Valet will ask for your password when it starts."
          fi
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
        bash "$RUSTUP_INSTALLER" -y || setup_failed Rust
      else
        download_failed Rust
      fi

      rm -f "$RUSTUP_INSTALLER"
      ;;
    esac
  done <<< "$languages"
fi
