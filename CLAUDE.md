# dotfiles

Dotfiles managed with mise.
The repo mirrors `$HOME`;
`mise bootstrap dotfiles apply` reads `[dotfiles]` in `.config/mise/config.toml`
and symlinks each listed source under the repo to its `$HOME` target.
Homebrew packages stay in `.config/homebrew/Brewfile`
(managed by `brew bundle --global`).
See `README.md` for the user-facing workflow.

Because the entries are symlinks,
editing a file under the repo (e.g. `.config/nvim/init.lua`)
changes the live config immediately — no apply step.
Only *new* files need `mise bootstrap dotfiles apply`
before they exist in `$HOME`.
Global agent instructions live in `.claude/CLAUDE.md`,
symlinked to `~/.claude/CLAUDE.md`.
