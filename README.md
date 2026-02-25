# Omakma

An opinionated Omakase Developer Setup for macOS Sonoma 14.5 and newer heavily inspired by [Omakub](https://github.com/basecamp/omakub). Turn a fresh macOS installation into a fully-configured, beautiful, and modern web development system by running a single command.

## What You Get

**Terminal & Shell:** Alacritty, Ghostty, iTerm2, Oh My Zsh (with autosuggestions, syntax highlighting, z), Zellij, Neovim, fzf, ripgrep, bat, eza, zoxide, btop, fd, lazygit, lazydocker, fastfetch, git-delta

**Editors:** VS Code, Sublime Text

**Languages (selectable):** PHP, Ruby on Rails, Node.js, Go, Python, Rust — managed via Mise

**Databases (selectable):** MySQL, PostgreSQL, Redis — with TablePlus, Sequel Ace, DBngin

**Desktop Apps:** Google Chrome, Firefox, Alfred, Rectangle, Slack, Telegram, Postman, Proxyman, Termius, OrbStack, LocalSend, Claude CLI

**Themes:** 7 switchable themes (Default, Catppuccin, Nord, Everforest, Rose Pine, Ristretto, Solarized) across Alacritty, Ghostty, Zellij, Neovim, VS Code, and Sublime Text

**Fonts:** JetBrains Mono, Cascadia Mono, Fira Mono, Meslo (Nerd Font variants, switchable)

## Installation

With your fresh macOS installation done, open the Terminal app and enter:

```
bash < <(curl -sL https://raw.githubusercontent.com/cuonggt/omakma/master/boot.sh)
```

This will start the installation process. It's almost entirely automated.

## Installing a specific version

Set the `OMAKMA_REF` environment variable to install from a specific branch, tag, or commit:

```
OMAKMA_REF=my-branch bash < <(curl -sL https://raw.githubusercontent.com/cuonggt/omakma/master/boot.sh)
```

## License

Omakma is released under the [MIT License](https://opensource.org/licenses/MIT).
