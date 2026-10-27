# Omakma

An opinionated Omakase Developer Setup for macOS Sonoma 14.5 and newer heavily inspired by [Omakub](https://github.com/basecamp/omakub). Turn a fresh macOS installation into a fully-configured, beautiful, and modern web development system by running a single command.

## What You Get

**Terminal & Shell:** Alacritty, Ghostty, iTerm2, Oh My Zsh (with autosuggestions, syntax highlighting, z), Zellij, tmux, Neovim (LazyVim), fzf, ripgrep, bat, eza, zoxide, btop, fd, tlrc, lazygit, lazydocker, git-delta, git-flow, GitHub CLI, Claude Code, fastfetch, overmind, mailpit, mole, wget, gnu-sed

**Editors:** VS Code and Sublime Text, both configured and themed to match the terminal

**Languages (selectable):** Node.js, Go, Python and Ruby on Rails through [mise](https://mise.jdx.dev/), PHP through Homebrew with Composer and Laravel Valet, Rust through rustup. Bun is installed either way.

**Databases (selectable):** MySQL, PostgreSQL and Redis, offered during installation and available later with `omakma install`. TablePlus, Sequel Ace and DBngin are installed as standard, and DBngin runs its own instances, so no Homebrew database is preselected.

**Desktop Apps:** Google Chrome, Firefox, Alfred, Rectangle, Slack, Telegram, Postman, Proxyman, Termius, OrbStack, LocalSend, PHP Monitor, Macshot, Recordly, ChatGPT, Claude

**Optional Apps:** Cloudflare WARP, Dropbox, Pritunl and Xmind are offered during installation. Ollama, OpenKey, Spotify, Steam and Zoom can be added later with `omakma install`.

**Themes:** 7 switchable themes (Default, Catppuccin, Nord, Everforest, Rose Pine, Ristretto, Solarized) across Alacritty, Ghostty, Zellij, Neovim, VS Code and Sublime Text

**Fonts:** JetBrains Mono Nerd Font is installed up front; Cascadia Mono, Fira Mono and Meslo are one `omakma font` away

## Installation

With your fresh macOS installation done, open the Terminal app and enter:

```
bash < <(curl -sL https://raw.githubusercontent.com/cuonggt/omakma/master/boot.sh)
```

This will start the installation process. It's almost entirely automated.

You get the most recent [release](https://github.com/cuonggt/omakma/releases), rather than whatever `master` happens to be in the middle of. `omakma update` then tracks `master`, so fixes reach you without waiting for the next release.

## Installing a specific version

Set the `OMAKMA_REF` environment variable to install from a specific branch, tag, or commit:

```
OMAKMA_REF=my-branch bash < <(curl -sL https://raw.githubusercontent.com/cuonggt/omakma/master/boot.sh)
```

Use `OMAKMA_REF=master` to install the tip instead of the last release.

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

Every change is recorded in [CHANGELOG.md](CHANGELOG.md), which describes *why*
it was made rather than only what moved.

### Tests

`test/run.sh` exercises how the installers and uninstallers treat config under
your home directory.

```
test/run.sh            # every case file
test/run.sh alacritty  # just test/app-alacritty.sh
```

It is safe to run on a machine you care about: every case gets a throwaway
`HOME` under `$TMPDIR`, every `brew` call is stubbed, and nothing reaches the
network. A failing run lists what broke at the end, with the command that runs
just those case files again.

ShellCheck is the other gate:

```
test/lint.sh
```

CI runs both on every push and pull request to `master`, and any ShellCheck
finding fails the build. Note that the target is bash 3.2 -- macOS ships
`/bin/bash` 3.2.57 -- so ShellCheck will sometimes suggest syntax that is not
available here.

### What the tests do not cover

Config handling is the only part of the codebase with automated coverage, and
**no uninstaller has ever actually removed anything**: every `brew` call is
stubbed, so a green build shows that a script deletes the right config, never
that it uninstalls the package. Eight of the forty-four uninstallers have cases
covering which files they delete; the rest are unexercised. Try
`omakma uninstall` on a machine you can afford to break before trusting it.

### Migrations

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
