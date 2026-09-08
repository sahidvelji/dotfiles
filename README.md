# dotfiles

Sahid's dotfiles, managed with [mise](https://mise.jdx.dev/) (dotfiles + dev tools) and Homebrew (system packages).

## How it works

- The repo mirrors `$HOME` — e.g. `repo/.config/ghostty/config` maps to `~/.config/ghostty/config`
- `mise bootstrap dotfiles apply` reads `[dotfiles]` in `.config/mise/config.toml` and creates the symlinks (`symlink-each` walks each source dir recursively, linking every leaf file into the target)
- Homebrew packages live in `.config/homebrew/Brewfile` and install via `brew bundle --global`
- `mise.toml` defines a few small tasks that wrap brew commands

## Prerequisites

```bash
brew install mise
```

## Setup on a new machine

```bash
git clone https://github.com/sahidvelji/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
mise trust                 # required: mise refuses to load an untrusted config
mise run brew-install      # install Homebrew packages
mise bootstrap             # apply dotfiles, set login shell, install mise tools
```

If a real file in `$HOME` conflicts with a symlink mise wants to create,
`mise bootstrap dotfiles apply --force` will replace it. Move the original aside first
if you want to keep it.

## Tracking a new dotfile

```bash
mise bootstrap dotfiles add ~/.config/ghostty/config
```

`mise bootstrap dotfiles add` copies the live file under the dotfiles root and adds an
explicit `[dotfiles]` entry. For directory-scoped entries that are already
declared (e.g. `~/.config`), just drop the new file under the matching repo
path and re-run `mise bootstrap dotfiles apply`.

## Previewing dotfile changes

```bash
mise bootstrap dotfiles status              # applied/missing/differs per entry
mise bootstrap dotfiles apply --dry-run     # what would change
mise bootstrap dotfiles apply --dry-run --verbose
```

## Day-to-day workflow

Your dotfiles are symlinked, so editing `~/.config/ghostty/config` edits the repo copy directly.

## Untracking a dotfile

```bash
mise bootstrap dotfiles unapply ~/.config/ghostty/config
```

`unapply` removes the symlink but leaves anything mise cannot identify as
managed; modified copies and templates need `--force`. Then remove the entry
from `[dotfiles]` in `.config/mise/config.toml`, or delete the source from the
repo, so it is not re-applied.

## Brewfile

The `Brewfile` tracks installed Homebrew packages (taps, formulae, casks). It lives at `.config/homebrew/Brewfile` and is symlinked to `~/.config/homebrew/Brewfile` (the XDG location `brew bundle --global` reads).

```bash
mise run brew-dump      # update Brewfile with currently installed packages
mise run brew-install   # install packages from Brewfile
```

Run `mise run brew-dump` before committing to capture any new brew packages.
