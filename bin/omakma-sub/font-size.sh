choice=$(gum choose {10..16} "<< Back" --height 11 --header "Choose your terminal font size")

if [[ $choice =~ ^[0-9]+$ ]]; then
  gsed -i "s/^size = .*$/size = $choice/g" $HOME/.config/alacritty/font-size.toml
  source $OMAKMA_PATH/bin/omakma-sub/font-size.sh
else
  source $OMAKMA_PATH/bin/omakma-sub/font.sh
fi
