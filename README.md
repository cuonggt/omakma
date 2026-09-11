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

## Daily Use

Once installed, `omakma` opens an interactive menu:

```
omakma
```

Every entry is also a sub-command, so you can skip the menu:

| Command | What it does |
| --- | --- |
| `omakma theme` | Switch theme across Alacritty, Ghostty, Zellij, Neovim, VS Code and Sublime Text |
| `omakma font` | Switch the terminal font. Pass one to skip the picker: `omakma font "Fira Mono"` |
| `omakma font-size` | Set the terminal font size, 10 to 16 |
| `omakma install` | Install an optional app, or re-run any of the default installers |
| `omakma uninstall` | Remove an app Omakma installed, along with the config it put in place |
| `omakma update` | Update Omakma and apply any pending migrations |

## Updating

```
omakma update
```

This pulls the latest Omakma, then runs any migrations that have not yet run on
this machine. Migrations are one-off fixes that bring an existing install in
line with what a fresh one gets -- a setting that moved, a config that needs
rewriting -- so an old install does not drift from a new one. If a migration
fails it says which, and `omakma update` exits non-zero rather than reporting
success.

## Development

A fix made inside an installer only ever reaches machines set up after it. When
a change needs to reach existing installs too, add a migration:

```
omakma dev-add-migration <slug>
```

That writes `migrations/<unix-timestamp>_<slug>.sh`, which is sourced once per
machine on the next `omakma update`. Fresh installs skip every migration that
already exists: `install/preflight.sh` marks them applied before the installers
run, so historical fixes never run on a clean machine.

## License

Omakma is released under the [MIT License](https://opensource.org/licenses/MIT).
