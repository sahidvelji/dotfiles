# dotfiles

Dotfiles managed with mise. The repo mirrors `$HOME`; `mise dotfiles apply` reads `[dotfiles]` in `mise.toml` and symlinks each listed source under the repo to its `$HOME` target. Homebrew packages stay in `Brewfile` (managed by `brew bundle`). See `README.md` for the user-facing workflow.
