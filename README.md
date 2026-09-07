# dotfiles

Sahid's dotfiles, managed with [mise](https://mise.jdx.dev/) (dotfiles + dev tools) and Homebrew (system packages).

## How it works

- The repo mirrors `$HOME` — e.g. `repo/.config/ghostty/config` maps to `~/.config/ghostty/config`
- `mise dotfiles apply` reads `[dotfiles]` in `.config/mise/config.toml` and creates the symlinks (`symlink-each` walks each source dir recursively, linking every leaf file into the target)
- Homebrew packages live in `Brewfile` and install via `brew bundle`
- `mise.toml` defines a few small tasks that wrap brew commands

## Prerequisites

```bash
brew install mise
```

## Setup on a new machine

```bash
git clone https://github.com/sahidvelji/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
mise run brew-install      # install Homebrew packages
mise bootstrap             # apply dotfiles, set login shell, install mise tools
```

If a real file in `$HOME` conflicts with a symlink mise wants to create,
`mise dotfiles apply --force` will replace it. Move the original aside first
if you want to keep it.

## Tracking a new dotfile

```bash
mise dotfiles add ~/.config/ghostty/config
```

`mise dotfiles add` copies the live file under the dotfiles root and adds an
explicit `[dotfiles]` entry. For directory-scoped entries that are already
declared (e.g. `~/.config`), just drop the new file under the matching repo
path and re-run `mise dotfiles apply`.

## Previewing dotfile changes

```bash
mise dotfiles status                  # applied/missing/differs per entry
mise dotfiles apply --dry-run         # what would change
mise dotfiles apply --dry-run --verbose
```

## Day-to-day workflow

Your dotfiles are symlinked, so editing `~/.config/ghostty/config` edits the repo copy directly.

## Untracking a dotfile

Remove the entry from `[dotfiles]` in `.config/mise/config.toml` (or delete the source from
the repo). Mise keeps no state database, so the existing symlink in `$HOME`
stays in place — delete it by hand if you want it gone.

## Brewfile

The `Brewfile` tracks installed Homebrew packages (formulae, casks, taps, vscode extensions, npm globals). It lives at `.config/homebrew/Brewfile` and is symlinked to `~/.config/homebrew/Brewfile` (the XDG location `brew bundle --global` reads).

```bash
mise run brew-dump      # update Brewfile with currently installed packages
mise run brew-install   # install packages from Brewfile
```

Run `mise run brew-dump` before committing to capture any new brew packages.
