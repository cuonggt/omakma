# Install the optional apps chosen on first run, or ask when nothing chose them.
#
# Tested for being set rather than non-empty, which only matters because of the
# prompt below: an empty value is the user having chosen none of them on first
# run, and reading that as "never asked" would ask again part-way through the
# install. Its two siblings, select-dev-language.sh and select-dev-database.sh,
# have had both halves all along; this one had neither, so browsing to it
# through `omakma install` silently did nothing.
if [[ -n "${OMAKMA_FIRST_RUN_OPTIONAL_APPS+set}" ]]; then
  apps=$OMAKMA_FIRST_RUN_OPTIONAL_APPS
else
  OPTIONAL_APPS=("1111" "Dropbox" "Pritunl" "Xmind")
  # Nothing preselected, unlike the first-run prompt in
  # install/first-run-choices.sh: reaching this means picking what to add now,
  # not accepting a default set again.
  apps=$(gum choose "${OPTIONAL_APPS[@]}" --no-limit --height 7 --header "Select optional apps")
fi

if [[ -n "$apps" ]]; then
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    app=$(echo "$app" | tr '[:upper:]' '[:lower:]')
    source "$OMAKMA_PATH/install/desktop/optional/app-${app}.sh"
  done <<< "$apps"
fi
