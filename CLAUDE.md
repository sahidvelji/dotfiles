# dotfiles

Dotfiles managed with mise.
The repo mirrors `$HOME`;
`mise dot apply` reads `[dotfiles]` in `.config/mise/config.toml`
and symlinks each listed source under the repo to its `$HOME` target
(`mise dot` is the short spelling of `mise bootstrap dotfiles`).
Homebrew packages stay in `.config/homebrew/Brewfile`
(managed by `brew bundle --global`).
See `README.md` for the user-facing workflow.

Because the entries are symlinks,
editing a file under the repo (e.g. `.config/nvim/init.lua`)
changes the live config immediately — no apply step.
Only *new* files need `mise dot apply`
before they exist in `$HOME`.
Global agent instructions live in `.claude/CLAUDE.md`,
symlinked to `~/.claude/CLAUDE.md`.

## Git

Commit and push to `main` directly.
This repo does not use feature branches or pull requests,
so the usual "branch first when on the default branch" rule does not apply here.
Still ask before committing.
