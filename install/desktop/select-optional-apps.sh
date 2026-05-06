if [[ -n "${OMAKMA_FIRST_RUN_OPTIONAL_APPS}" ]]; then
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    app=$(echo "$app" | tr '[:upper:]' '[:lower:]')
    source "$OMAKMA_PATH/install/desktop/optional/app-${app}.sh"
  done <<< "$OMAKMA_FIRST_RUN_OPTIONAL_APPS"
fi
