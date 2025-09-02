if [ ! -d /Applications/Visual\ Studio\ Code.app ]; then
  brew install --cask visual-studio-code
fi

sudo ln -fs /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code /usr/local/bin/code
mkdir -p $HOME/Library/Application\ Support/Code/User
[ -f "$HOME/Library/Application\ Support/Code/User/settings.json" ] && mv $HOME/Library/Application\ Support/Code/User/settings.json $HOME/Library/Application\ Support/Code/User/settings.json.bak
cp $HOME/.local/share/omakma/configs/vscode.json $HOME/Library/Application\ Support/Code/User/settings.json

# Install extensions
code --install-extension patbenatar.advanced-new-file
code --install-extension steoates.autoimport
code --install-extension antfu.icons-carbon
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension naumovs.color-highlight
code --install-extension ms-azuretools.vscode-docker
code --install-extension EditorConfig.EditorConfig
code --install-extension usernamehw.errorlens
code --install-extension dbaeumer.vscode-eslint
code --install-extension tamasfe.even-better-toml
code --install-extension file-icons.file-icons
code --install-extension eamodio.gitlens
code --install-extension golang.Go
code --install-extension Lokalise.i18n-ally
code --install-extension antfu.iconify
code --install-extension Zignd.html-css-class-completion
code --install-extension christian-kohler.npm-intellisense
code --install-extension christian-kohler.path-intellisense
code --install-extension bmewburn.vscode-intelephense-client
code --install-extension MehediDracula.php-namespace-resolver
code --install-extension esbenp.prettier-vscode
code --install-extension rubocop.vscode-rubocop
code --install-extension Shopify.ruby-extensions-pack
code --install-extension richie5um2.vscode-sort-json
code --install-extension unional.vscode-sort-package-json
code --install-extension ms-vscode.sublime-keybindings
code --install-extension jock.svg
code --install-extension bradlc.vscode-tailwindcss
code --install-extension antfu.theme-vitesse
code --install-extension redhat.vscode-yaml
code --install-extension laravel.vscode-laravel
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension Vue.volar
