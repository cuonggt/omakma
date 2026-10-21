# Changelog

All notable changes to Omakma are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Migrations under `migrations/` describe *what* changed for existing
installs; this file describes *why*.

## [Unreleased]

### Fixed

- The keep-awake no longer outlives a failed install. `install/terminal.sh` and
  `install/desktop.sh` backgrounded `caffeinate -dims` and killed it after their
  installer loop, so under `set -e` any failure in that loop skipped the kill
  and left the process running -- holding the Mac awake indefinitely, with
  nothing on screen to say so and nothing short of `pkill` to stop it. Two
  helpers, `keep_awake` and `let_sleep`, now stop it from an EXIT trap as well
  as explicitly at the end of the loop. The trap is re-armed per loop, so the
  terminal and desktop passes cannot strand each other's.

## [0.1.0] - 2026-10-21

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

- `omakma uninstall` no longer claims success regardless. `app_uninstall` and
  `brew_app_uninstall` both ended in `|| true` with stderr discarded, so an
  uninstaller always returned 0 and the `&&` chain in
  `bin/omakma-sub/uninstall.sh` always reached its "Uninstall completed!"
  spinner -- with the app still installed, and Homebrew's explanation thrown
  away. The helpers now tell three outcomes apart: a package that is not
  installed is nothing to do (which is what keeps them safe to re-run, so it
  stays silent), a clean removal is not reported, and a removal Homebrew refuses
  is recorded through `uninstall_failed` with its reason left on screen.
  `report_failed_uninstalls` names them, and the menu skips its `clear` when
  there is something to read, since clearing was wiping the only account of it.
  A refused removal does not stop the uninstaller: the config cleanup still
  runs, and the summary says so.

- The last two installers that called Homebrew by hand now survive it too.
  `install/desktop/app-localsend.sh` and `install/desktop/app-phpmon.sh` need a
  `brew tap` before installing, so neither could go through `app_install` or
  `brew_app_install` and both were missed by the two changes above: a failure in
  either still took the whole install down. All three taps involved are
  third-party, and `brew tap` can fail on its own when one is renamed, removed
  or untrusted, so a failure at any step is now recorded once and the install
  carries on. Every `brew install` and `brew tap` under `install/` is now either
  behind a helper or explicitly tolerant, with `install/terminal/required/app-gum.sh`
  as the single deliberate exception.

- The terminal installers survive an unavailable package too. The previous
  change covered `app_install` and `brew_app_install`, which only the desktop
  installers use; the 15 files under `install/terminal/` called `brew list X ||
  brew install X` directly, 30 times over, so one disabled formula still took
  the whole run down -- and `install/terminal.sh` runs *before*
  `install/desktop.sh`, so it took the desktop installers with it. Two new
  helpers, `brew_install` and `cask_install`, carry the same record-and-continue
  behaviour, and every one of those 30 sites now uses them. Three places needed
  more than a substitution: `app-neovim.sh` keeps its `command -v nvim` guard so
  an nvim installed by other means is left alone; `select-dev-language.sh` now
  skips Composer and Valet when PHP could not be installed, and skips Ruby, Node,
  Go and Python when mise is missing, since tolerating those installs while
  leaving their dependents unguarded would only move the failure one line down;
  and `install/terminal/required/app-gum.sh` stays fail-fast on purpose, because
  `gum` drives the first-run choices and both menus.

- A package Homebrew will not install no longer kills the whole run. The
  `alacritty` cask was disabled upstream on 2026-09-01 for failing the macOS
  Gatekeeper check, and Homebrew raises rather than warns when asked to install
  a disabled cask on a machine that does not have it. `install.sh` runs under
  `set -e`, `install/desktop.sh` sources its installers in a loop, and
  `app-alacritty.sh` is alphabetically the first of 28 -- so a fresh install
  died at the first desktop app, losing the other 27 along with the Dock and
  font tweaks and the reboot prompt, and leaking the `caffeinate` process that
  `desktop.sh` starts and never got to kill. The retry the ERR trap suggests
  could never succeed. `app_install` and `brew_app_install` now record a package
  Homebrew refuses, say so, and carry on; `report_failed_installs` names
  everything skipped just before the reboot prompt. Only the `brew install`
  itself is tolerated -- every other failure still stops the install, which is
  covered by a test. The Alacritty installer stays in place rather than being
  removed, so it starts working again if the cask is re-enabled.

- The test suite no longer trusts an inherited `OMAKMA_PATH`. `defaults/bash/shell`
  exports it as `~/.local/share/omakma`, so a shell that had sourced Omakma's own
  config made `test/run.sh` exercise the *installed* copy rather than the
  checkout -- failing for the wrong reason against an old install, and worse,
  passing for the wrong reason against a merely different one. It is now derived
  from the test directory's own location. Related: `assert_says` could never
  match anything written to stderr, because the redirection sat on the
  assignment rather than inside the command substitution.

- ShellCheck now covers the bash files that carry no extension, which the
  `find -name '*.sh'` pattern had never reached: `bin/omakma`, the shipped
  `configs/bashrc`, and the helpers under `defaults/bash/` -- including
  `defaults/bash/functions`, which every installer depends on and which had
  therefore never been linted in CI. `test/lint.sh` is now the single
  definition of what gets linted, used by CI and documented in CLAUDE.md so
  the two cannot drift; it globs `defaults/bash/` rather than listing it, so a
  new helper cannot escape the linter by being new. The readline files
  (`defaults/bash/inputrc`, `configs/inputrc`) and `configs/zshrc` stay out:
  the first two are not shell, and ShellCheck cannot check zsh. Widening the
  net surfaced eleven findings in `defaults/bash/aliases` and
  `defaults/bash/rc` -- unquoted paths, legacy backticks, and three aliases
  that expanded `$HOME` when defined rather than when used -- all fixed
  without changing what any of them do.

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
