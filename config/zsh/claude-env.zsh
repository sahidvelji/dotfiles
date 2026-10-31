# Run by Claude Code before each Bash command (CLAUDE_ENV_FILE in ~/.zshenv).
# Its PATH is a snapshot from startup, so tool dirs that `mise activate` set for
# the launch directory would otherwise beat the pins of any repo it moves into.
export PATH="$XDG_DATA_HOME/mise/shims:$PATH"
