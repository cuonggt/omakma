# Run any pending Omakma migrations.
#
# Migration files live in $OMAKMA_PATH/migrations and are named
# <unix-timestamp>_<slug>.sh. Each migration runs at most once per machine;
# success is recorded by touching an empty marker file under
# $OMAKMA_STATE_HOME/migrations/<basename>.

OMAKMA_STATE_HOME="${OMAKMA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/omakma}"
OMAKMA_MIGRATIONS_DIR="$OMAKMA_PATH/migrations"
OMAKMA_MIGRATIONS_STATE="$OMAKMA_STATE_HOME/migrations"

mkdir -p "$OMAKMA_MIGRATIONS_STATE"

# Pathname expansion returns its matches sorted, and the unix-timestamp prefix
# makes that lexicographic order chronological.
shopt -s nullglob
migrations=("$OMAKMA_MIGRATIONS_DIR"/*.sh)
shopt -u nullglob

# Guarded on the count rather than expanded straight away: bash 3.2 treats
# "${empty[@]}" as an unbound variable under `set -u`, so a machine with no
# pending migrations would have died here the moment anything sourcing this set
# it. bash 4.4 and later do not, so CI could never have caught it -- macOS ships
# 3.2.57, which is the only version that matters.
if [ "${#migrations[@]}" -gt 0 ]; then
  for migration in "${migrations[@]}"; do
    basename=$(basename "$migration")
    marker="$OMAKMA_MIGRATIONS_STATE/$basename"

    [[ -e "$marker" ]] && continue

    echo "Running migration: $basename"
    if ( source "$migration" ); then
      touch "$marker"
    else
      echo "Migration failed: $basename"
      return 1 2>/dev/null || exit 1
    fi
  done
fi
