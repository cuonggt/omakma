AVAILABLE_DBS=("MySQL" "Redis" "PostgreSQL")
dbs=$(gum choose "${AVAILABLE_DBS[@]}" --no-limit --height 5 --header "Select databases")

if [[ -n "$dbs" ]]; then
  for db in $dbs; do
    case $db in
    MySQL)
      brew install mysql@8.4
      ;;
    Redis)
      brew install redis
      ;;
    PostgreSQL)
      brew install postgresql@16
      ;;
    esac
  done
fi
