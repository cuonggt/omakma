set -e

ascii_art='                       __
  ____   _____ _____  |  | _______    _____ _____
 /  _ \ /     \\__  \ |  |/ /\__  \  /     \\__  \
(  <_> )  Y Y  \/ __ \|    <  / __ \|  Y Y  \/ __ \_
 \____/|__|_|  (____  /__|_ \(____  /__|_|  (____  /
             \/     \/     \/     \/      \/     \/
'

echo -e "$ascii_art"
echo "=> Omakma is for fresh macOS Sonoma 14.5 installations only!"
echo -e "\nBegin installation (or abort with ctrl+c)..."

echo "Cloning Omakma..."
rm -rf $HOME/.local/share/omakma
git clone https://github.com/cuonggt/omakma.git $HOME/.local/share/omakma >/dev/null
if [[ $OMAKMA_REF != "master" ]]; then
  cd $HOME/.local/share/omakma
  git fetch origin "${OMAKMA_REF:-stable}" && git checkout "${OMAKMA_REF:-stable}"
  cd -
fi

echo "Installation starting..."
source $HOME/.local/share/omakma/install.sh
