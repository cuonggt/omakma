# Install selected databases
if [[ -n "${OMAKMA_FIRST_RUN_DATABASES+set}" ]]; then
  dbs=$OMAKMA_FIRST_RUN_DATABASES
else
  AVAILABLE_DBS=("MySQL" "Redis" "PostgreSQL")
  dbs=$(gum choose "${AVAILABLE_DBS[@]}" --no-limit --height 5 --header "Select databases")
fi

if [[ -n "$dbs" ]]; then
  while IFS= read -r db; do
    case "$db" in
    MySQL)
      brew_install mysql@8.4
      ;;
    Redis)
      brew_install redis
      ;;
    PostgreSQL)
      brew_install postgresql@16
      ;;
    esac
  done <<< "$dbs"
fi
