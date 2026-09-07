# dotfiles

Dotfiles managed with mise. The repo mirrors `$HOME`; `mise dotfiles apply` reads `[dotfiles]` in `.config/mise/config.toml` and symlinks each listed source under the repo to its `$HOME` target. Homebrew packages stay in `.config/homebrew/Brewfile` (managed by `brew bundle --global`). See `README.md` for the user-facing workflow.
