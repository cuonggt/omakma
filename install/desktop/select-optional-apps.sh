if [[ -n "${OMAKMA_FIRST_RUN_OPTIONAL_APPS}" ]]; then
  apps=$OMAKMA_FIRST_RUN_OPTIONAL_APPS

  if [[ -n "$apps" ]]; then
    for app in $apps; do
      source "$OMAKMA_PATH/install/desktop/optional/app-${app}.sh"
    done
  fi
fi
