# dotfiles

Sahid's dotfiles,
managed with [mise](https://mise.jdx.dev/) (dotfiles + dev tools)
and Homebrew (system packages).

## How it works

- Each top-level directory is a mise
  [dotfile group](https://mise.jdx.dev/dotfiles/groups.html)
  deployed into the matching dot-directory —
  e.g. `repo/config/ghostty/config` maps to `~/.config/ghostty/config`:

  | Repo               | Target                 |
  | ------------------ | ---------------------- |
  | `config/`          | `~/.config`            |
  | `local/`           | `~/.local`             |
  | `claude/`          | `~/.claude`            |
  | `zshenv`           | `~/.zshenv`            |
  | `config/zsh/zshrc` | `~/.config/zsh/.zshrc` |

- `mise dot apply` reads the groups and `[dotfiles]` in the repo's `mise.toml`
  and creates the symlinks
  (each group walks its directory recursively,
  linking every leaf file into the target)
- The same file declares macOS preferences under `[bootstrap.macos]`,
  defines a few small tasks scoped to this repo,
  and pins the lint tools
- Homebrew packages live in `config/homebrew/Brewfile`
  and install via `mise run brew-install`
- `config/mise/config.toml` is the global mise config,
  and `config/mise/tasks/` holds global tasks that run from anywhere
- `hk.pkl` lints and formats every commit

The dotfiles and bootstrap config is project config,
so run `mise dot` and `mise bootstrap` from the repo,
or from anywhere with `mise -C ~/repos/dotfiles`.

`mise dot` is the short spelling of `mise dotfiles` / `mise bootstrap dotfiles`.

## Prerequisites

Install [Homebrew](https://brew.sh) first, then mise:

```bash
brew install mise
```

## Setup on a new machine

```bash
git clone https://github.com/sahidvelji/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
mise trust                 # required: mise refuses to load an untrusted config
mise run brew-install      # install Homebrew packages
mise bootstrap             # dotfiles, macOS defaults, login shell, tools
```

Order matters: the declared Dock layout names applications by path,
and mise refuses to apply a layout naming an app that is not installed yet.

If a real file in `$HOME` conflicts with a symlink mise wants to create,
`mise dot apply --force` will replace it.
Move the original aside first if you want to keep it.

## Tracking a new dotfile

```bash
cd ~/repos/dotfiles
mise dot add ~/.config/ghostty/config
```

A file under `~/.config`, `~/.local` or `~/.claude`
belongs to that directory's group,
so `mise dot add` moves it into the group (`config/ghostty/config`)
and links it back, without a new config entry.
Run it from the repo:
elsewhere mise does not see the groups,
so it would move the file into `~/.dotfiles`
and write an entry for it into the global config,
`config/mise/config.toml`.

A new top-level dotfile matches no group.
Give it a dotless source and write the entry to the repo's `mise.toml`:

```bash
mise dot add --local --source ~/repos/dotfiles/foo ~/.foo
```

Keep the source absolute:
mise 2026.10.18 links a relative `--source` as written,
so `~/.foo` would point at `foo` beside it
until the next `mise dot apply`.

A group keeps source names as they are,
so a new dotfile nested inside one,
such as `~/.config/zsh/.zprofile`,
would land in the repo with its dot.
Move it to a dotless name under the group instead,
declare it like `.zshrc` under `[dotfile_groups.config.entries]`
in `mise.toml`,
and run `mise dot apply`:

```toml
"~/.config/zsh/.zprofile" = { source = "zsh/zprofile" }
```

## Checking state

```bash
mise bootstrap status            # dotfiles, preferences, login shell, tools
mise bootstrap status --missing  # same listing, exit 1 if anything drifted
mise dot status                  # dotfile entries only, plus history state
mise dot apply --dry-run         # what an apply would change (add --verbose)
```

## Day-to-day workflow

Your dotfiles are symlinked,
so editing `~/.config/ghostty/config` edits the repo copy directly.

## Untracking a dotfile

Delete the source from the repo, then apply:

```bash
git rm config/ghostty/config
mise dot apply
```

A group links each file,
so the next apply removes the link of a deleted source.
For an entry in `[dotfiles]`,
run `mise dot unapply <target>` before removing the entry.
After removing a whole group,
`mise dot apply --prune` removes the files it left behind.

## macOS settings

Preferences live in the repo's `mise.toml` alongside the dotfile groups,
in three spellings:
friendly sections (`[bootstrap.macos.dock]`, `.finder`, `.trackpad`)
for common settings;
raw domains (`[bootstrap.macos.defaults."<domain>"]`) for everything else,
third-party apps included;
and `[[bootstrap.macos.defaults_entries]]` for `defaults -currentHost`
preferences, which are scoped to one machine rather than the user account.
`[bootstrap.macos.login_items]` lists the apps that open at login;
it only adds entries, so apps that register themselves are left alone.

```bash
mise bootstrap macos defaults status     # set / differs / unset per key
mise bootstrap macos defaults apply --dry-run
mise bootstrap macos defaults apply
```

Only values that differ from stock macOS are recorded.
mise never deletes a default,
so declaring one cannot change a machine —
it only buries the settings that carry real intent.

Values are strictly typed:
an integer `1` does not satisfy a declared `true`,
nor a plist real a declared integer.

There is no capture command —
nothing plays `brew bundle dump` to `brew bundle`.
Going the other way is hand-editing,
with `defaults read <domain> <key>` and `defaults read-type` for the value
and its plist type.

App preferences belong here rather than as symlinked `.plist` files under
`~/Library/Preferences`, which `cfprefsd` caches —
a running app can hold a newer value than the one on disk.

Dock and Control Center changes need a relaunch:
`[bootstrap.hooks.post-defaults]` runs `killall Dock ControlCenter` after every
`mise bootstrap`; after a standalone `apply`, run it yourself.

## Brewfile

The `Brewfile` tracks installed Homebrew packages (taps, formulae, casks).
It lives at `config/homebrew/Brewfile`
and is symlinked to `~/.config/homebrew/Brewfile`
(the XDG location `brew bundle --global` reads).
The tasks below run in the repo's `config/homebrew` directory instead,
so they work on a fresh Mac before that symlink exists.

```bash
mise run brew-dump      # update Brewfile with currently installed packages
mise run brew-install   # install packages from Brewfile
```

Run `mise run brew-dump` before committing to capture any new brew packages.

## Tasks

`mise.toml` at the repo root holds tasks scoped to this repo
(`brew-dump`, `brew-install`);
they are only visible from inside it.
`config/mise/tasks/` holds global file tasks,
symlinked into `~/.config/mise/tasks/`,
so they run from any directory.
Under `config/` mise also reads them,
and `config/mise/config.toml`, as project config,
so run mise from the repo root.

```bash
mise run repos-tidy                       # tidy the repo you are standing in
mise run repos-tidy --all                 # every repo under ~/repos
mise run repos-tidy hk pklr               # only these, named by directory
mise run repos-tidy --all --jobs 8        # ...eight at a time
mise run repos-tidy --all --dry-run       # report only; touches nothing
mise run repos-tidy --all --force-closed  # also prune unmerged closed PR branches
```

For each repo it fetches every remote with `--prune`,
then fast-forwards the default branch —
skipping the pull when the worktree is dirty,
and updating the branch without a checkout
when the repo is sitting on a feature branch.
Local-branch pruning is delegated to
[`gh-poi`](https://github.com/seachicken/gh-poi),
which deletes branches whose pull request has merged.

Two details worth knowing:

- `gh-poi` will not delete the branch that is checked out,
  so a repo left sitting on a branch whose PR has already merged
  would never be pruned.
  `repos-tidy` switches back to the default branch first,
  but only when the worktree is clean
  and nothing is still open for the same head.
- `--dry-run` skips the fetch as well as every write,
  so the "behind by N" counts it reports
  come from the last real run rather than from the remote.

Repos with a detached HEAD are reported and skipped.
The default branch is refreshed from whatever it actually tracks,
which in a fork is `upstream` rather than the fork's own `origin`.

A new task file needs `mise dot apply` before it is runnable from elsewhere.

## Linting

[hk](https://hk.jdx.dev/) checks each commit.
The global git hooks in `config/git/config` run hk in any repo
that has an `hk.pkl`,
so this repo needs no hook setup of its own.
The linters and formatters are pinned in `mise.toml`.

```bash
hk check --all   # lint every file
hk fix --all     # apply every available fix
HK=0 git commit  # skip the hooks for one commit
```

`hk.pkl` lists the linter and formatter for each file type.
Tool settings sit beside it
(`.editorconfig` for shfmt and stylua, `biome.json`, `ryl.toml`, `tombi.toml`)
or next to the config they cover
(`config/nvim/selene.toml` and `vim.yml`).

## Claude Code config

`claude/` is a group like any other:
it links each leaf into `~/.claude/`,
leaving Claude Code's runtime state
(`projects/`, `sessions/`, `history.jsonl`) untouched
because those paths have no source in the repo.

- `claude/CLAUDE.md` — global instructions that apply in every project
  (PR and commit conventions, task-runner preferences, markdown style)
- `claude/settings.json` — model, permission mode, editor mode, status line
- `claude/statusline-command.sh` — the status line renderer
  that `settings.json` points at

Editing any of these takes effect in the next session,
since their `~/.claude` counterparts are symlinks.
Adding a new file under `claude/`
needs `mise dot apply` before Claude Code will see it.
