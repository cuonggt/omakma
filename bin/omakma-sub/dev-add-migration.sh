# Scaffold a new migration file in $OMAKMA_PATH/migrations.
#
# Usage: omakma dev-add-migration <slug>
# Example: omakma dev-add-migration rename_optional_apps
#   -> creates migrations/<unix-ts>_rename_optional_apps.sh

SLUG="$1"

if [[ -z "$SLUG" ]]; then
  echo "Usage: omakma dev-add-migration <slug>"
  return 1 2>/dev/null || exit 1
fi

# Sanitize: lowercase, spaces/dashes -> underscores, drop other punctuation.
SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | tr ' -' '__' | tr -cd 'a-z0-9_')

TS=$(date +%s)
FILE="$OMAKMA_PATH/migrations/${TS}_${SLUG}.sh"

mkdir -p "$OMAKMA_PATH/migrations"

cat >"$FILE" <<'EOF'
# Describe the change here. This script is sourced once on every existing
# machine the next time `omakma update` runs. It is skipped on fresh installs
# (preflight pre-touches the marker).
EOF

echo "Created $FILE"
