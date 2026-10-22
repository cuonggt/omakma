set_font() {
  local font_name=$1
  local url=$2
  local file_type=$3
  local file_name="${font_name/ Nerd Font/}"

  if ! fc-list | grep -qi "$font_name"; then
    if wget -q -O "/tmp/$file_name.zip" "$url"; then
      unzip -o "/tmp/$file_name.zip" -d "/tmp/$file_name"
      cp "/tmp/$file_name"/*."$file_type" "$HOME/Library/Fonts"
      rm -rf "/tmp/$file_name.zip" "/tmp/$file_name"
      fc-cache
      clear
      source "$OMAKMA_PATH/ascii.sh"
    else
      echo "Failed to download $font_name font"
    fi
  fi

  # Each is skipped when the app's config is not there, so changing font after
  # uninstalling something says nothing rather than failing on every file.
  update_config "$OMAKMA_PATH/configs/alacritty/fonts/$file_name.toml" "$HOME/.config/alacritty/font.toml"

  edit_config "$HOME/.config/ghostty/config" "s/^font-family = .*$/font-family = $font_name/g"

  edit_config "$HOME/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings" \
    "s/\"font_face\": \".*\"/\"font_face\": \"$file_name Nerd Font Mono, monospace\"/g"

  edit_config "$HOME/Library/Application Support/Code/User/settings.json" \
    "s/\"editor.fontFamily\": \".*\"/\"editor.fontFamily\": \"$file_name Nerd Font Mono, monospace\"/g"
}

FONT_NAMES=("JetBrains Mono" "Cascadia Mono" "Fira Mono" "Meslo")

# Sub-commands are handed their own arguments, so `omakma font "Fira Mono"`
# arrives here as $1.
if [ "$#" -gt 0 ]; then
  choice=$1
else
  choice=$(gum choose "${FONT_NAMES[@]}" "> Change size" "<< Back" --height 8 --header "Choose your programming font")
fi

case $choice in
"JetBrains Mono")
  set_font "JetBrainsMono Nerd Font" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" "ttf"
  ;;
"Cascadia Mono")
  set_font "CaskaydiaMono Nerd Font" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip" "ttf"
  ;;
"Fira Mono")
  set_font "FiraMono Nerd Font" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraMono.zip" "otf"
  ;;
"Meslo")
  set_font "MesloLGS Nerd Font" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" "ttf"
  ;;
"> Change size")
  source "$OMAKMA_PATH/bin/omakma-sub/font-size.sh"
  exit
  ;;
esac

source "$OMAKMA_PATH/bin/omakma-sub/menu.sh"
