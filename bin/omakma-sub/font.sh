set_font() {
  local font_name=$1
  local url=$2
  local file_type=$3
  local file_name="${font_name/ Nerd Font/}"

  if ! $(fc-list | grep -i "$font_name" >/dev/null); then
    cd /tmp
    wget -O "$file_name.zip" "$url"
    unzip "$file_name.zip" -d "$file_name"
    cp "$file_name"/*."$file_type" /Library/Fonts
    rm -rf "$file_name.zip" "$file_name"
    fc-cache
    cd -
    clear
    source $OMAKMA_PATH/ascii.sh
  fi

  cp "$OMAKMA_PATH/configs/alacritty/fonts/$file_name.toml" ~/.config/alacritty/font.toml
  gsed -i "s/\"font_face\": \".*\"/\"font_face\": \"$file_name Nerd Font Mono, monospace\"/g" $HOME/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
  # gsed -i "s/\"editor.fontFamily\": \".*\"/\"editor.fontFamily\": \"$file_name Nerd Font Mono, monospace\"/g" $HOME/Library/Application\ Support/Code/User/settings.json
}

if [ "$#" -gt 1 ]; then
  choice=${!#}
else
  choice=$(gum choose "JetBrains Mono" "Cascadia Mono" "Fira Mono" "Meslo" "> Change size" "<< Back" --height 8 --header "Choose your programming font")
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
  source $OMAKMA_PATH/bin/omakma-sub/font-size.sh
  exit
  ;;
esac

source $OMAKMA_PATH/bin/omakma-sub/menu.sh
