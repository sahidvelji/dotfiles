# dotfiles

Dotfiles managed with mise.
Each top-level directory is a mise dotfile group
deployed into the matching dot-directory of `$HOME`
(`config/` into `~/.config`);
`zshenv` and `config/zsh/zshrc` are the dotless exceptions.
The groups, `[dotfiles]` and `[bootstrap]` live in the global mise config,
`config/mise/config.toml`.
Homebrew packages stay in `config/homebrew/Brewfile`,
installed with `mise run brew-install`
and refreshed with `mise run brew-dump`.
See `README.md` for the user-facing workflow.

Because the groups symlink each file,
editing a file under the repo (e.g. `config/nvim/init.lua`)
changes the live config immediately — no apply step.
Only *new* files need `mise dot apply`
before they exist in `$HOME`.
Global agent instructions live in `claude/CLAUDE.md`,
symlinked to `~/.claude/CLAUDE.md`.

Track new files with `mise dot add`,
which moves each into the group whose target holds it.
A dotfile keeps its dot, so rename it in the repo to drop the dot,
give it an explicit entry in `config/mise/config.toml`
like `.zshrc` and `.zshenv`,
and run `mise dot apply`.

Under `config/`, mise also reads the global config and its tasks
as project config.

## Linting

The pre-commit hook runs `hk.pkl`'s linters and formatters on staged files,
so a commit may restage reformatted files or fail on a lint error.
Fix the cause rather than skipping the hook with `HK=0` or `--no-verify`.

## Git

Commit and push to `main` directly.
This repo does not use feature branches or pull requests,
so the usual "branch first when on the default branch" rule does not apply here.
Still ask before committing.
