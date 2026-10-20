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
- Reusable installer helpers in `defaults/bash/functions`: `app_installed`,
  `app_install`, `brew_app_install`, `app_uninstall`, `brew_app_uninstall`
  and `copy_config`. Sourced by `install.sh` and `bin/omakma`, so all
  installers (initial bootstrap and post-install menu) share them.
- A databases prompt at first run, alongside optional apps and languages.
  `select-dev-database.sh` moved up out of `install/terminal/optional/`,
  which `install/terminal.sh` never descended into, so MySQL, PostgreSQL
  and Redis were only reachable through `omakma install`. Nothing is
  preselected: DBngin ships by default and runs its own instances.
- A test suite, `test/`, covering how installers and uninstallers treat config
  under the user's home -- the first automated coverage in the project, and the
  gap that let 44 uninstallers merge unexercised. `test/run.sh` is the entry
  point, with one case file per app. Each case gets a throwaway `HOME` under
  `$TMPDIR` and every `brew` call is stubbed, so it is safe to run on a working
  machine and needs no network; `test/helpers.sh` refuses a `HOME` outside its
  sandbox, since these cases delete config directories. 70 assertions, run by
  CI on every push and pull request (`.github/workflows/test.yml`).

- `install/trust-taps.sh`, which trusts the five Homebrew taps Omakma
  installs from (localsend, nicoverbruggen, shivammathur/php,
  lazydocker, bun). Recent Homebrew asks before loading anything from an
  untrusted tap, which interrupts the install. Taps the user added
  themselves are left alone.
- `CHANGELOG.md` (this file).

### Fixed

- The Neovim, fastfetch and zellij uninstallers no longer delete config
  directories they do not own. Each of those installers deliberately writes
  nothing when a config is already there -- `[ ! -d "$HOME/.config/nvim" ]`
  and the like -- and the uninstaller then ran `rm -rf` on the whole
  directory, so a user who already had a Neovim config lost it with no
  backup anywhere, Omakma never having written one. They now remove only
  files that still match the copy Omakma installed (any theme's copy counts,
  since `omakma theme` recopies some of them), prune the directory only if it
  ends up empty, and report anything they kept. `~/.config/nvim` is never
  removed: Omakma strips `.git` from the LazyVim starter so the user can
  adopt it, which leaves the clone indistinguishable from a config they wrote
  themselves. Two new helpers in `defaults/bash/functions`,
  `remove_installed_config` and `remove_empty_dir`, carry the logic.

- The Alacritty and Ghostty uninstallers no longer take their whole config
  directory either, which needed the installers fixing first: both wrote with
  plain `cp`, so a user's own `alacritty.toml` or ghostty `config` was
  destroyed at install time with no backup, leaving the uninstaller nothing it
  could put back. Both installers now write every file through `copy_config`,
  and both uninstallers remove only files that still match a copy Omakma
  installed, restore the `.bak` once Omakma's own file is gone, and prune the
  directory only if it empties. `omakma theme` and `omakma font` recopy
  `theme.toml` and `font.toml`, so any theme's or font's copy counts as ours;
  `font-size.toml` and ghostty's `config` are rewritten line-by-line in place
  instead, so once a size, font or theme has been changed those two read as
  user edits and stay. A third helper, `restore_config_backup`, carries the
  restore.

- `copy_config` no longer writes a `.bak` when the file already matches what
  is about to replace it. There is nothing of the user's to keep in that case,
  and the backup is worse than none: re-running an installer from `omakma
  install` on a machine already set up left a `.bak` of Omakma's own config
  behind, which an uninstaller cannot tell from a real one and would dutifully
  restore -- so uninstalling put the whole config back and achieved nothing.
  This affects every caller, `.zshrc`, `.gitconfig`, VS Code and Sublime
  included.

- An empty first-run selection is no longer read as "never asked".
  Deselecting every language meant `select-dev-language.sh` prompted
  again in the middle of the install; it now checks whether the variable
  was set rather than whether it holds anything.
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
- Installers that cannot use `app_install` -- LocalSend and PHP Monitor
  need taps, Recordly is a DMG download -- now guard on `app_installed`,
  so `/Applications` is named in one place.
- Configs that overwrite a file the user may already own (`.zshrc`,
  `.bashrc`, `.inputrc`, `.gitconfig`, VS Code and Sublime settings) go
  through `copy_config`, which no longer overwrites an existing `.bak`.
  Re-running an installer used to replace the user's original backup with
  Omakma's own copy from the previous run. `.gitconfig` was not backed up
  at all before.
- Dropped `set_default`: its fixed four arguments could not express
  `defaults write com.apple.dock persistent-apps -array`, which writes an
  empty array -- through the wrapper it would have written an array
  holding one empty string.
- Installing no longer overwrites Preferred Languages. Setting
  `AppleLanguages` to `en-US` dropped every other language the user reads
  macOS in; only the Region (`AppleLocale`) is set now, which is what the
  UTF-8 locale actually depends on.

## [0.0.1] - 2026-03-09

- Initial release.
