# macOS derives a terminal's LANG from the system Region (AppleLocale). When
# the Region has no matching UTF-8 locale -- en_VN, for example, which has no
# en_VN.UTF-8 -- LC_CTYPE silently falls back to the non-UTF-8 "C" locale and
# tools start reporting "Setting locale failed".
#
# install.sh normalises this on fresh machines. Installs predating that never
# got it, so bring them in line -- but only when the Region is actually broken,
# and only after asking: Region and Preferred Languages are system-wide
# settings the user may well have chosen on purpose.

apple_locale=$(defaults read NSGlobalDomain AppleLocale 2>/dev/null)
apple_locale=${apple_locale%%@*} # strip extensions, e.g. en_VN@currency=USD

if [[ -n "$apple_locale" ]] && locale -a | grep -qixF "$apple_locale.UTF-8"; then
  echo "  Region is $apple_locale, which has a matching UTF-8 locale. Nothing to do."
  return 0 2>/dev/null || exit 0
fi

languages=$(defaults read NSGlobalDomain AppleLanguages 2>/dev/null | tr -d ' \n"')

echo "  Region \"${apple_locale:-unset}\" has no matching UTF-8 locale, so terminal"
echo "  programs fall back to the non-UTF-8 \"C\" locale."
echo ""
echo "  Omakma can set Region to en_US and Preferred Languages to en-US, which is"
echo "  what a fresh install does. This replaces your current languages:"
echo "    ${languages:-unset}"
echo ""

if gum confirm "Set the system locale to en_US.UTF-8?"; then
  defaults write NSGlobalDomain AppleLocale -string "en_US"
  defaults write NSGlobalDomain AppleLanguages -array "en-US"
  echo "  Done. Log out and back in for every app to pick up the new locale."
else
  echo "  Skipped -- leaving your Region and languages alone."
  echo "  Export LANG and LC_ALL in your shell config if you hit locale warnings."
fi
