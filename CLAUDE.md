# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Omakma is an opinionated macOS developer environment bootstrapper (macOS Sonoma 14.5+), inspired by [Omakub](https://github.com/basecamp/omakub). It automates turning a fresh macOS installation into a fully-configured web development system via a single command. The entire codebase is pure Bash shell scripts (~80 files).

## Architecture

**Installation flow:** `boot.sh` → `install.sh` → `install/terminal.sh` + `install/desktop.sh`

- `boot.sh` — Entry point (run via curl). Installs Xcode CLT, clones repo to `~/.local/share/omakma`, runs `install.sh`
- `install.sh` — Main orchestrator. Installs Homebrew, runs interactive choices via `gum`, then sources terminal and desktop installers
- `install/terminal/` — Individual installer scripts for CLI tools, languages, and databases
- `install/desktop/` — Individual installer scripts for GUI applications
- `bin/omakma` — Post-install runtime command providing an interactive menu
- `bin/omakma-sub/` — Sub-commands: `menu.sh`, `theme.sh`, `font.sh`, `font-size.sh`, `install.sh`, `update.sh`

**Theme system:** 7 themes (default, catppuccin, nord, everforest, rose-pine, ristretto, solarized) in `themes/`. Each theme directory contains config files for alacritty, ghostty, vscode, sublime, neovim, and zellij. Theme switching is unified via `bin/omakma-sub/theme.sh`.

**Configuration files:** `configs/` contains dotfiles and settings (zshrc, gitconfig, vscode.json, alacritty/, neovim/, sublime/). `defaults/bash/` contains shell aliases, prompt, and init scripts.

## Key Conventions

- The main `install.sh` uses `set -e` for fail-fast behavior; most other scripts are sourced from it or run independently without it
- Homebrew is the primary package manager (`brew install` / `brew install --cask`)
- Interactive prompts use `gum` (text UI framework, installed as a required dependency)
- Language versions are managed via `mise` (not asdf)
- The install path is `$OMAKMA_PATH` (`~/.local/share/omakma`)

## Code Style

- Shell scripts: 2-space indentation, UTF-8, LF line endings (see `.editorconfig`)
- No build system, linter, or test suite — changes are verified by running the scripts
