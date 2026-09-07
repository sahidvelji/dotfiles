#!/bin/zsh
# ~/.zshenv — sourced for EVERY zsh (login, interactive, and non-interactive
# `zsh -c` / scripts / cron / git hooks). zsh reads this from $HOME because
# ZDOTDIR is not set yet; we set it here so the rest of the config loads from
# XDG. Keep this file cheap and subprocess-free. Interactive-only setup
# (prompt, plugins, keybindings, shortcut regen) lives in $ZDOTDIR/.zshrc.

# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Load the rest of the zsh config from XDG.
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Default Programs
export VISUAL="nvim"
export EDITOR="$VISUAL"
export BROWSER="open"
export TERMINAL="ghostty"

# ~/ clean-up: redirect tool state/config to XDG paths.
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export INPUTRC="$XDG_CONFIG_HOME/shell/inputrc"
export NVM_DIR="$XDG_DATA_HOME/nvm"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export PYTHON_HISTORY="$XDG_STATE_HOME/python_history"
# Stops /etc/zshrc_Apple_Terminal (Terminal.app only) recreating ~/.zsh_sessions.
export SHELL_SESSIONS_DISABLE=1

# Tool options that non-interactive tools may also read.
export CLICOLOR=

# Homebrew (hardcoded — avoids a `brew shellenv` subprocess).
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"

# PATH — dirs we always want at the front. `.zshrc` re-asserts this prefix
# because macOS `path_helper` (run by /etc/zprofile) reorders PATH for login
# shells and pushes Homebrew behind /usr/bin. `typeset -U` keeps PATH
# de-duplicated so the re-assert is a no-op reorder. `homebrew_path` stays
# defined for the same process so .zshrc can reuse it without duplication.
typeset -Ua homebrew_path=(
  /opt/homebrew/bin
  /opt/homebrew/sbin
  "$HOME/.local/bin"
  "$XDG_DATA_HOME/go/bin"
  "$XDG_DATA_HOME/cargo/bin"
  /opt/homebrew/opt/util-linux/bin
  /opt/homebrew/opt/util-linux/sbin
)
typeset -U path
path=($homebrew_path $path)
