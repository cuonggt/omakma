# Pre-install setup that must happen before any installer runs.
#
# Pre-touch all current migration markers so that historical migrations
# (which exist only to fix up older installs) do not run on a fresh machine.

OMAKMA_STATE_HOME="${OMAKMA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/omakma}"
OMAKMA_MIGRATIONS_STATE="$OMAKMA_STATE_HOME/migrations"

mkdir -p "$OMAKMA_MIGRATIONS_STATE"

shopt -s nullglob
for migration in "$OMAKMA_PATH"/migrations/*.sh; do
  touch "$OMAKMA_MIGRATIONS_STATE/$(basename "$migration")"
done
shopt -u nullglob
