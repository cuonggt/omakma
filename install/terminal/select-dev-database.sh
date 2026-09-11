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
      brew list mysql@8.4 &>/dev/null || brew install mysql@8.4
      ;;
    Redis)
      brew list redis &>/dev/null || brew install redis
      ;;
    PostgreSQL)
      brew list postgresql@16 &>/dev/null || brew install postgresql@16
      ;;
    esac
  done <<< "$dbs"
fi
