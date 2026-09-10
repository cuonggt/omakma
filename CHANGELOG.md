# Changelog

All notable changes to Omakma are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Migrations under `migrations/` describe *what* changed for existing
installs; this file describes *why*.

## [Unreleased]

### Added

- Migrations system (`migrations/`, `bin/omakma-sub/migrate.sh`,
  `bin/omakma-sub/dev-add-migration.sh`). `omakma update` now applies any
  pending migrations after `git pull`. Fresh installs pre-touch markers in
  `install/preflight.sh` so historical fixes don't run on a clean machine.
  A failed migration stops the run, names the migration that failed, and
  makes `omakma update` exit non-zero; so does a failed `git pull`.
- Uninstall mirrors under `uninstall/` for every `install/.../app-*.sh`,
  plus an `Uninstall` entry in the interactive menu (`omakma uninstall`)
  that picks an uninstaller via `gum file`.
- Reusable installer helpers in `defaults/bash/functions`: `app_install`,
  `brew_app_install`, `app_uninstall`, `brew_app_uninstall`, `copy_config`,
  `set_default`. Sourced by `install.sh` and `bin/omakma`, so all
  installers (initial bootstrap and post-install menu) share them.
- `CHANGELOG.md` (this file).

### Fixed

- Two locale fixes that previously only reached fresh machines are now
  backfilled to existing installs as migrations. The Omakma iTerm2 profile
  is pinned to `en_US.UTF-8` (and a leftover
  `DynamicProfiles/omakma.json` removed); a system Region with no matching
  UTF-8 locale -- `en_VN`, say, which leaves `LC_CTYPE` on `C` -- can be
  normalised to `en_US`. The system-locale one asks before changing
  anything, since Region and Preferred Languages may be deliberate, and
  the iTerm2 one defers while iTerm2 is running rather than having its
  changes overwritten on quit.

### Changed

- `bin/omakma` now forwards CLI args to sub-commands (e.g.
  `omakma dev-add-migration <slug>`) and prefixes the version line with
  `v` in the banner.
- The simple desktop installers were collapsed from a 3-line guard to a
  single `app_install <cask>` (or `brew_app_install`) call.

## [0.0.1] - 2026-03-09

- Initial release.
