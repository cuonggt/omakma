# macOS derives a terminal's LANG from the system Region (AppleLocale). When
# the Region has no matching UTF-8 locale -- en_VN, for example, which has no
# en_VN.UTF-8 -- LC_CTYPE silently falls back to the non-UTF-8 "C" locale and
# tools start reporting "Setting locale failed".
#
# install.sh normalises this on fresh machines. Installs predating that never
# got it, so bring them in line -- but only when the Region is actually broken,
# and only after asking: the Region is system-wide and the user may well have
# chosen it on purpose.

apple_locale=$(defaults read NSGlobalDomain AppleLocale 2>/dev/null)
apple_locale=${apple_locale%%@*} # strip extensions, e.g. en_VN@currency=USD

if [[ -n "$apple_locale" ]] && locale -a | grep -qixF "$apple_locale.UTF-8"; then
  echo "  Region is $apple_locale, which has a matching UTF-8 locale. Nothing to do."
  return 0 2>/dev/null || exit 0
fi

echo "  Region \"${apple_locale:-unset}\" has no matching UTF-8 locale, so terminal"
echo "  programs fall back to the non-UTF-8 \"C\" locale."
echo ""
echo "  Omakma can set the Region to en_US, which is what a fresh install does."
echo "  Date and number formats follow the Region, so those change too. Your"
echo "  Preferred Languages are left alone."
echo ""

if gum confirm "Set the system Region to en_US?"; then
  defaults write NSGlobalDomain AppleLocale -string "en_US"
  echo "  Done. Log out and back in for every app to pick up the new locale."
else
  echo "  Skipped -- leaving your Region alone."
  echo "  Export LANG and LC_ALL in your shell config if you hit locale warnings."
fi
