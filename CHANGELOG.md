# Changelog

All notable changes to Omakma are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Migrations under `migrations/` describe *what* changed for existing
installs; this file describes *why*.

## [Unreleased]

Nothing yet.

## [0.2.12] - 2026-10-27

### Fixed

- `omakma theme` no longer configures Sublime Text or VS Code for a theme whose
  files never arrived. `themes/set-sublime-theme.sh` cloned the colour scheme
  package with a bare `git clone` rather than `clone_if_missing`, and
  `themes/set-vscode-theme.sh` ran `code --install-extension` unguarded; both
  then rewrote the app's config regardless, naming a scheme inside a package
  that was not there or a theme from an extension that had not installed. Each
  now reports the failure and leaves the previous working theme in place, which
  is the only one of the two outcomes the user can undo. A failure in one app
  still lets the others be themed.

## [0.2.11] - 2026-10-27

### Fixed

- `install/desktop/select-optional-apps.sh` asks which optional apps to install
  when nothing has chosen them, instead of silently installing none. Its two
  siblings, `select-dev-language.sh` and `select-dev-database.sh`, have always
  had that fallback; this one had none, so reaching it through `omakma install`
  did nothing at all. It also tested `${OMAKMA_FIRST_RUN_OPTIONAL_APPS}` for
  being non-empty rather than set, which the prompt now makes load-bearing: an
  empty value is the user having chosen none of them on first run, and reading
  that as "never asked" interrupts an install that is already running to ask a
  second time. The old form was additionally a `set -u` hazard -- a plain
  reference to an unset variable is a fatal unbound-variable error, where
  `${VAR+set}` is safe by construction -- which never fired only because
  `install.sh` does not use `set -u`.

### Removed

- The second Ollama installer. There were two -- `brew_install ollama` under
  `install/terminal/optional/` and `brew_app_install ollama` under
  `install/desktop/optional/`, with byte-identical uninstallers -- and the
  desktop pair was reachable only through the install menu's file browser, since
  the menu routes the name to the terminal copy. It was also the wrong one:
  Homebrew's `ollama` is a formula with no app bundle, so `brew_app_install`
  guarded on an `/Applications/Ollama.app` the formula never creates and the
  guard could never fire. `test/menu.sh` now drives every install-menu entry
  through the real dispatch and checks it resolves to a file that is there,
  which is what makes removing one safe.

## [0.2.10] - 2026-10-27

### Fixed

- `omakma update` no longer blames the network for every failure, and no longer
  strands the machine. It ran `git pull --rebase` and printed "check your
  network connection" whatever went wrong, so a checkout the user had edited,
  or one carrying a local commit, sent them to their router over the one thing
  only they could fix. Worse, a rebase that stopped part-way was left where it
  stopped: the checkout ends up on a detached HEAD with unmerged files, "try
  again" fails forever after that, and a detached HEAD is the single state
  `install/pin-to-release.sh` exists to avoid -- `git pull` has nothing to
  follow, so no fix ever reaches the machine again. A half-finished rebase is
  now undone and the checkout left exactly as it was, and a dirty checkout, a
  detached HEAD, a branch tracking nothing and a rebase left over from an
  earlier attempt are each identified before the network is touched and given
  the command that clears them. The fetch and the rebase run as two steps, so
  being offline and having diverged no longer share a message.

## [0.2.9] - 2026-10-27

### Changed

- `test/run.sh` re-lists every failed assertion at the end of a failing run,
  each with the case file it came from, and prints the command that runs just
  those files again. A full run is over five hundred lines, so the handful that
  matter scroll off the top: one CI run came back 229/1 with the log truncated
  above the failure, which left nothing to diagnose and nothing to reproduce. A
  passing run is unchanged.
- The README's Development section covers the test suite and ShellCheck, points
  at this file, and says plainly what the tests do not cover. Until now a
  contributor browsing the repository had no way to discover that `test/run.sh`
  and `test/lint.sh` exist, or that CI gates on both -- it was written only in
  `CLAUDE.md`, which is guidance for an assistant rather than documentation for
  a person. The uninstaller coverage count there was also stale: eight of the
  forty-four have cases now, not five.

## [0.2.8] - 2026-10-27

### Fixed

- Four failure messages blamed the network for something that had downloaded
  fine and then failed to run: the Oh My Zsh and rustup installers, and a
  Recordly disk image that either would not mount or had no app inside. They
  report through `setup_failed` now. The wording is the whole change and the
  whole point of it -- sending someone to look at their router over an
  installer that ran and failed is its own kind of failure looking like a
  success.

## [0.2.7] - 2026-10-27

### Fixed

- A failed Composer download no longer ends the whole install. The bootstrap in
  `install/terminal/select-dev-language.sh` fetched the installer with
  `php -r "copy(...)"`, which exits 0 when the download fails and writes no
  file, so the line after it ran php against a file that was not there. Under
  `set -e` that ended the run at the retry message before `install/desktop.sh`
  had been reached at all -- no desktop apps, no Dock, no themes, no fonts. PHP
  is preselected in `install/first-run-choices.sh`, so this was every default
  install on a bad connection.
- The Composer installer is verified before it runs, against the checksum
  Composer publishes on a separate host, rather than being downloaded and
  executed unchecked.
- Neither `composer-setup.php` nor the phar is written into the directory the
  install was started from. Nothing in the install ever `cd`s, so for the
  documented one-liner that was the user's home, and the setup script was left
  sitting there whenever a later step failed.
- `composer global require laravel/valet`, `valet install` and `valet trust`
  are each guarded, and Valet is looked for again after the require rather than
  assumed onto PATH -- a failed require left `valet install` to run as a command
  that was not there, taking the install with it.

### Added

- `setup_failed`, alongside `download_failed`, for something that arrived and
  then could not be set up. The two differ only in what they say, which is the
  point: reporting a failed `valet install` as a failed download sends the user
  off to look at their network.
- `test/dev-language.sh`, covering the nine ways the Composer bootstrap can
  fail plus the happy path, and taking the suite to 364 assertions. It hashes
  through a stubbed php rather than for real, so the cases need no hash tool of
  their own -- plain Ubuntu has no `shasum`, which is also why the installer
  hashes with php.

## [0.2.6] - 2026-10-22

### Fixed

- `boot.sh` stops when the clone fails. It had no guard and no `set -e`, so a
  failed clone carried on to source two paths that were not there, reporting
  the missing files rather than the clone that never happened.

### Changed

- `boot.sh`'s first two steps are now the functions `install_xcode_clt` and
  `clone_omakma`, and sourcing it with `$OMAKMA_BOOT_DEFINE_ONLY` set defines
  them without running anything. They run before the repository exists, so
  unlike `install/pin-to-release.sh` they cannot live inside it -- this is what
  makes them reachable by a test at all, and they are the first script every
  user runs. `$OMAKMA_CLONE_URL` and `$OMAKMA_CLONE_PATH` let a test clone a
  local repository into a sandbox instead of GitHub into a home directory.
  Covered by `test/boot-steps.sh`, including the grep/tail/sed pipeline that
  picks the Command Line Tools label out of `softwareupdate -l`, which had
  never been exercised.

## [0.2.5] - 2026-10-22

### Fixed

- `omakma install` no longer claims success when a package was skipped. It
  gated its "Install completed!" spinner on the sourced installer's exit
  status, but the install helpers return 0 when Homebrew will not hand a
  package over or a download fails -- so the spinner always fired, and the
  `clear` right after it wiped the "Could not install..." message that was the
  only account of what had happened. `report_failed_installs` was never called
  in that path either, so everything the summary exists to say was invisible
  unless you happened to be doing a full fresh install. The dispatch now checks
  the failure list rather than an exit status, and keeps the screen when there
  is something to read -- the same fix the uninstall menu already had.

- `omakma install` slugs its choice with `tr` rather than `gsed`, since gnu-sed
  is installable but skippable and a missing one would have blanked the choice
  and sourced a path that is not there.

## [0.2.4] - 2026-10-22

### Fixed

- A failed download no longer ends the install. Every `curl`, `wget` and
  `git clone` under `install/` ran unguarded while `install.sh` runs under
  `set -e`, so a network blip aborted the whole run -- and
  `install/terminal/a-shell.sh` clones three repositories among the very first
  things a fresh install does, since it sorts first of the terminal installers
  and those run before the desktop ones. The same shape as a cask disabled
  upstream, with a different cause. Two new helpers, `download_failed` and
  `clone_if_missing`, record what could not be fetched and carry on, sharing
  the summary that already named skipped packages.

- Oh My Zsh and Rust no longer fail silently. Both were installed with
  `sh -c "$(curl ...)"`, which turns a failed download into `sh -c ""` -- that
  succeeds, so nothing was installed and nothing said so. In Oh My Zsh's case
  the three plugin clones two lines later then failed into a `.oh-my-zsh` that
  was not there, which is what actually ended the run. Both now fetch to a file
  and check it, and the plugins are skipped when Oh My Zsh is absent.

- `install/desktop/app-recordly.sh` takes its mount point from `hdiutil`
  rather than searching all of `/Volumes`, which could have found a
  `Recordly.app` on an unrelated disk, and detaches the image whether or not
  the app was found -- a bad image used to stay mounted. Its download comes
  from a third-party GitHub release, so it was the likeliest of all of these to
  fail.

- `install/terminal/app-neovim.sh` creates `lua/plugins` before writing the
  theme into it. The LazyVim starter ships that directory, so this never
  failed, but the copy was one upstream layout change away from ending the
  install.

## [0.2.3] - 2026-10-22

### Fixed

- `omakma theme` and `omakma font` no longer fail on every app the user has
  uninstalled. Both edited config files in place and copied theme files in as
  though each app were still installed, so switching theme on a machine with
  anything removed printed a dozen `No such file or directory` errors from a
  routine operation and then redrew the menu as though nothing had happened.
  Two new helpers, `edit_config` and `update_config`, skip an app whose config
  is not there. `themes/set-sublime-theme.sh` went further and git-cloned a
  colour scheme repository into a directory tree for a Sublime Text that was
  not installed; it now does nothing at all without Sublime's config. The
  Sublime and VS Code cases were made reachable by this release's own uninstall
  changes, which started removing config those switchers had always assumed.

- `omakma font` creates `~/Library/Fonts` before copying a downloaded font into
  it. `install/desktop/fonts.sh` creates it at install time, so `omakma font`
  had never needed to -- but it should not depend on having been run after it.

- `edit_config` takes GNU sed under either name, `gsed` on macOS or `sed`
  elsewhere, rather than assuming `gsed`. It refuses to fall back to BSD sed,
  which reads the expression as `-i`'s backup suffix and mangles the file, and
  says so instead. `omakma theme` also slugs its choice with `tr` rather than
  `gsed`, since gnu-sed is installable but skippable and a missing one there
  would have silently blanked the choice.

## [0.2.2] - 2026-10-22

### Fixed

- A removal Homebrew refuses now stops the uninstaller instead of carrying on
  to delete the app's config. You could end up with the app still installed and
  its configuration gone -- worse than a failed uninstall, because the app is
  left working but unconfigured and the config cannot be put back.
  `uninstall_failed` now returns non-zero and the twelve uninstallers with
  anything to do after the removal stop on it, with a test asserting that none
  of them can be added later without the guard. The reported summary used to
  say the config had been removed anyway; it now says it was left in place.

- Uninstalling an app now gives its Homebrew tap back. Omakma taps five
  repositories and untapped none of them, so uninstalling LocalSend, PHP
  Monitor, lazydocker or bun left a tap behind for good. Each of those four
  uninstallers now calls a new `untap_if_unused` helper, which untaps only
  while nothing is still installed from the tap. That guard is the point rather
  than a nicety: `brew untap` on a tap that still has packages installed offers
  to uninstall them first and prompts while doing it, so an unguarded untap
  could take unrelated packages with it. `shivammathur/php` is deliberately
  left alone -- `omakma install` installs PHP versions from it, so it outlives
  any single app that needs it, and a test asserts no uninstaller ever passes
  it.

## [0.2.1] - 2026-10-22

### Changed

- A fresh install now gets the most recent release rather than whatever `master`
  happens to be in the middle of, while `omakma update` keeps tracking `master`
  -- so installs are pinned and updates are not, and a fix still reaches
  existing machines without waiting for the next tag. Until now `boot.sh`
  cloned `master` unpinned, which made both tags purely decorative.
  `install/pin-to-release.sh` holds the choice, and moves `master` back to the
  tag with `git reset` rather than checking the tag out: a detached HEAD would
  leave `git pull` with nothing to follow and no fix would reach the machine
  again. `$OMAKMA_REF` still overrides everything, with `master` for the tip,
  and a repository with no tags yet installs `master` and says so. One useful
  side effect: `install/preflight.sh` now pre-touches only the migration
  markers that existed at the release, so migrations added afterwards do run on
  the first `omakma update` -- which is what they are for.

- `test/run.sh` sources every `*.sh` in `test/` bar its own three
  infrastructure files, rather than matching `app-*` and `helpers-*`. A new
  case file could previously be added and silently never run.

## [0.2.0] - 2026-10-21

### Fixed

- Installing iTerm2 no longer destroys the profiles you already had. The
  installer assigned `New Bookmarks` a one-item list, so every profile in
  `~/Library/Preferences/com.googlecode.iterm2.plist` was replaced by Omakma's
  the moment Omakma was installed, with no backup to recover them from -- the
  one place in the project that lost user data outright rather than overwriting
  a file it could back up. It now adds its profile alongside whatever is there,
  backs the plist up through a new `backup_config` helper first, and re-uses the
  guid from a previous run so anything iTerm2 has bound to that profile keeps
  working. A first install still claims the default profile and the two
  appearance keys; a re-run only takes them back while they are still pointing
  at Omakma's own, so a default or tab style the user has since chosen is
  theirs to keep. It also defers while iTerm2 is running, as the uninstaller
  does, because iTerm2 writes its preferences back when it quits -- easy to hit
  from `omakma install`, where the terminal running it may well be iTerm2.

- The iTerm2, Sublime Text and Visual Studio Code uninstallers no longer leave
  the config their installers rewrote. All three removed the app and stopped,
  so reinstalling it from anywhere brought Omakma's settings back, and the
  user's own stayed buried in a `.bak` with nothing to restore them. VS Code's
  `settings.json` and Sublime's two `.sublime-settings` files are now removed
  while they still match what Omakma installed, with the `.bak` handed back;
  `omakma theme` and `omakma font` rewrite lines in both in place, so once
  either has run the file reads as a user edit and stays. Sublime's seven
  cloned packages, and the colour scheme package `omakma theme` clones, are
  removed through a new `remove_installed_clone` helper that checks the remote
  url, since the installer skips a package directory that already exists and a
  clone cannot be byte-matched. Package Control is left alone: it updates
  itself, so there is no way to tell Omakma's copy from the user's. iTerm2's
  profile, the default-profile guid pointing at it, and the two appearance keys
  the installer sets are cleared out of
  `~/Library/Preferences/com.googlecode.iterm2.plist`, deferring while iTerm2
  is running because it writes its preferences back when it quits. What it
  cannot do is restore the profiles that were there before: the installer
  replaces them outright and takes no backup, so they are gone at install time.

- `/usr/local/bin/code` is only removed while it is still the symlink the
  installer made, and `sudo` is not called at all when there is nothing to
  remove -- `sudo rm -f` on a path that is already gone still stops to ask for
  a password, so re-running the uninstaller asked for one to do nothing.

- The test harness can no longer touch the machine. `run_script` stubbed the
  install helpers but not `sudo`, `brew`, `code`, `curl`, `wget` or `git clone`,
  so sourcing a real installer ran them for real -- which it did, reinstalling
  two VS Code extensions and attempting a `sudo ln -fs` into `/usr/local/bin`
  before it was stopped. Those commands are now blocked inside `run_script`,
  loudly rather than silently, so a case that depends on one fails instead of
  quietly doing something real.

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
