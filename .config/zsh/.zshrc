# PATH — re-assert our prefix. macOS `path_helper` (/etc/zprofile) runs after
# ~/.zshenv on login shells and pushes Homebrew behind /usr/bin. `homebrew_path`
# is defined in ~/.zshenv; `typeset -U path` keeps this de-duplicated so this is
# just a reorder. Also put Homebrew's completions on fpath before compinit.
path=($homebrew_path $path)
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# Shell Options
setopt autocd # Automatically cd into typed directory.
stty stop undef # Disable ctrl-s to freeze terminal.
setopt interactive_comments
setopt EXTENDED_GLOB               # Enable ** ~ ^ glob operators
unsetopt NOMATCH                   # Pass unmatched globs through (like bash)

# History
HISTSIZE=10000000
SAVEHIST=10000000
# State, not cache: history cannot be regenerated, and ~/.cache/zsh otherwise
# holds only throwaway init caches and zcompdump.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST  # Trim duplicates first when history is full
setopt SHARE_HISTORY           # Share history across concurrent sessions
setopt EXTENDED_HISTORY        # Timestamp + duration; SHARE_HISTORY alone does not write these
setopt HIST_FCNTL_LOCK         # fcntl locking, safer with concurrent SHARE_HISTORY writers
setopt HIST_REDUCE_BLANKS          # Remove extra blanks from commands
setopt HIST_VERIFY                 # Show expanded history before executing (!! safety)

_shell_dir="${XDG_CONFIG_HOME:-$HOME/.config}/shell"

# Bookmark shortcuts. `generate-shortcuts` turns shell/bm-dirs and shell/bm-files
# into shortcutrc (aliases: h, cac, dl, cfz...) and zshnameddirrc (~h, ~cac...).
# Regenerated only when a bookmark file is newer than the output, so the usual
# case costs two stat calls. The nvim BufWritePost hook also regenerates on save.
if (( $+commands[generate-shortcuts] )) && [[ ! -s "$_shell_dir/shortcutrc" \
    || "$_shell_dir/bm-dirs" -nt "$_shell_dir/shortcutrc" \
    || "$_shell_dir/bm-files" -nt "$_shell_dir/shortcutrc" ]]; then
    generate-shortcuts
fi

# Source aliases and the generated shortcuts
[ -f "$_shell_dir/aliasrc" ] && source "$_shell_dir/aliasrc"
[ -f "$_shell_dir/shortcutrc" ] && source "$_shell_dir/shortcutrc"
[ -f "$_shell_dir/zshnameddirrc" ] && source "$_shell_dir/zshnameddirrc"

unset _shell_dir

# Completions
fpath=("${XDG_CONFIG_HOME:-$HOME/.config}/zsh/completions" $fpath)

fpath=("/opt/homebrew/share/zsh-completions" $fpath)

autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit -i -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
_comp_options+=(globdots) # Include hidden files.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Vi Mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Change cursor shape for different vi modes.
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[2 q';;      # block
        viins|main) echo -ne '\e[6 q';; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[6 q"
}
zle -N zle-line-init
echo -ne '\e[6 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[6 q' ;} # Use beam shape cursor for each new prompt.

# Key Bindings
bindkey -s "^p" "..\n"
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# FZF options + widgets (interactive)
export FZF_DEFAULT_OPTS="--layout=reverse --height 40% --bind=ctrl-z:ignore"
export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range :200 {} 2>/dev/null || eza --tree --level=2 --icons=always --color=always {}'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons=always --color=always {}'"
export FZF_CTRL_R_OPTS="--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command to clipboard'"
[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
bindkey '^f' fzf-cd-widget

# Cached Tool Initialization
_cached_source() {
    local name="$1"
    shift
    local cmd="$1"
    local cache="$XDG_CACHE_HOME/zsh/init/${name}.zsh"
    local bin_path="${commands[$cmd]}"

    # Regenerate if cache is missing, empty, or older than the binary
    if [[ ! -s "$cache" || "$bin_path" -nt "$cache" ]]; then
        mkdir -p "${cache:h}"
        "$@" > "$cache" 2>/dev/null
    fi

    source "$cache"
}

(( $+commands[starship] )) && _cached_source starship starship init zsh
(( $+commands[zoxide] ))   && _cached_source zoxide zoxide init zsh

[ -f /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh ] && source /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh
[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=
[ -f /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh ] && source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down

# NOT cached: `mise activate zsh` embeds a snapshot of the live $PATH in its
# output, so a cached copy replays a stale PATH and wipes the prefix set in
# ~/.zshenv (~/.local/bin, go/cargo bins, util-linux).
(( $+commands[mise] )) && eval "$(mise activate zsh)"
