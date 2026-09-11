# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Omakma is an opinionated macOS developer environment bootstrapper (macOS Sonoma 14.5+), inspired by [Omakub](https://github.com/basecamp/omakub). It automates turning a fresh macOS installation into a fully-configured web development system via a single command. The entire codebase is pure Bash shell scripts (over 130 of them).

## Architecture

**Installation flow:** `boot.sh` → `install.sh` → `install/terminal.sh` + `install/desktop.sh`

- `boot.sh` — Entry point (run via curl). Installs Xcode CLT, clones repo to `~/.local/share/omakma`, runs `install.sh`
- `install.sh` — Main orchestrator. Installs Homebrew, sources `defaults/bash/functions`, runs `install/preflight.sh` and the first-run choices via `gum`, then sources the terminal and desktop installers
- `install/terminal/` — Individual installer scripts for CLI tools, languages, and databases
- `install/desktop/` — Individual installer scripts for GUI applications
- `uninstall/` — Mirrors `install/` one-for-one. Each script removes a package and the config its installer put in place, and is meant to be safe to re-run when the app is already gone. **None of these has been run yet.** They were written and reviewed as a batch and merged unexercised; several remove files with `sudo rm -f`. CI only lints, so a green build says nothing about whether they work. Treat them as unverified, and exercise `omakma uninstall` on a machine you can afford to break before trusting one
- `migrations/` — One-off fixes for machines that are already installed (see below)
- `bin/omakma` — Post-install runtime command providing an interactive menu
- `bin/omakma-sub/` — Sub-commands: `menu.sh`, `theme.sh`, `font.sh`, `font-size.sh`, `install.sh`, `uninstall.sh`, `update.sh`, `migrate.sh`, `dev-add-migration.sh`. `menu.sh` shifts off the sub-command name and forwards the rest, so a sub-command reads its own arguments from `$1`

**`install/terminal.sh` and `install/desktop.sh` glob `*.sh` in their own directory only.** Scripts under `optional/` and `required/` are not picked up automatically — they run only where something sources them explicitly (the first-run choices, or `omakma install`). Putting a script in `optional/` is how it gets excluded from a default install.

**Migrations:** A fix made inside an installer only ever reaches machines set up after it. When a change needs to reach existing installs too, add a migration with `omakma dev-add-migration <slug>`, which scaffolds `migrations/<unix-timestamp>_<slug>.sh`. `omakma update` sources each one at most once per machine, recording success as an empty marker under `$OMAKMA_STATE_HOME/migrations/` (`~/.local/state/omakma` by default). `install/preflight.sh` pre-touches every marker on a fresh install, so historical fixes never run on a clean machine. A migration that fails stops the run, names itself, and makes `omakma update` exit non-zero.

A migration should not simply re-source its installer. Installers are written for fresh machines and can be destructive on one that is already set up — `install/desktop/app-iterm2.sh`, for instance, replaces *every* iTerm2 profile with Omakma's. Patch narrowly instead, and read the wanted values out of `configs/` so the migration and the installer cannot drift apart.

**Theme system:** 7 themes (default, catppuccin, nord, everforest, rose-pine, ristretto, solarized) in `themes/`. Each theme directory contains config files for alacritty, ghostty, vscode, sublime, neovim, and zellij. Theme switching is unified via `bin/omakma-sub/theme.sh`.

**Configuration files:** `configs/` contains dotfiles and settings (zshrc, gitconfig, vscode.json, alacritty/, neovim/, sublime/). `defaults/bash/` contains shell aliases, prompt, and init scripts, plus the shared installer helpers in `functions`.

## Key Conventions

- **Target bash 3.2.** macOS ships `/bin/bash` 3.2.57, so no `mapfile`, no associative arrays, no `${var^^}`. ShellCheck assumes a modern bash and will suggest otherwise — do not take that advice.
- **Installers, sub-commands, and migrations are sourced, not executed.** Stopping early therefore means `return N 2>/dev/null || exit N`; the `exit` half keeps a script usable when run directly, which is how these get tested.
- Use the helpers in `defaults/bash/functions` for new installers: `app_installed`, `app_install`, `brew_app_install`, `app_uninstall`, `brew_app_uninstall`, `copy_config`. Reach for `copy_config` for any file the user may already own — it keeps the original as `<file>.bak` and never overwrites an existing backup.
- An installer that taps (`brew tap x/y`, or a tap-qualified `brew install x/y/z`) needs its tap added to `install/trust-taps.sh`, or a fresh install stops on Homebrew's trust prompt.
- Every `install/**/app-*.sh` should have a matching `uninstall/**/app-*.sh`, with the exception of `install/terminal/required/`: `gum` drives the uninstaller's own UI, so there is deliberately no way to remove it.
- First-run choices are exported as `OMAKMA_FIRST_RUN_*` and consumed by the `select-*.sh` installers. Test whether the variable is **set** (`${VAR+set}`), not whether it is non-empty: an empty value means the user chose nothing, and reading that as "never asked" produces a second prompt partway through the install.
- The main `install.sh` uses `set -e` for fail-fast behavior; most other scripts are sourced from it or run independently without it
- Homebrew is the primary package manager (`brew install` / `brew install --cask`)
- Interactive prompts use `gum` (text UI framework, installed as a required dependency)
- Language versions are managed via `mise` (not asdf)
- The install path is `$OMAKMA_PATH` (`~/.local/share/omakma`)

## Code Style

- Shell scripts: 2-space indentation, UTF-8, LF line endings (see `.editorconfig`)
- No build system or test suite — behavioral changes are verified by running the scripts

## ShellCheck

ShellCheck runs in CI (`.github/workflows/shellcheck.yml`) on every push and pull request to master, across every `*.sh` file, and any finding fails the build. Run it before pushing:

```
find . -name '*.sh' -not -path './.git/*' | xargs shellcheck
```

`.shellcheckrc` holds the repo-wide exemptions that follow from everything being sourced (SC1090, SC1091, SC2034, SC2154, SC2317) and sets `shell=bash` so files without a shebang are still checked as bash. Exemptions that apply to the whole codebase belong there, with a comment explaining why, rather than as inline `# shellcheck disable=` comments repeated at each site.
