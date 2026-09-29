# PATH — re-assert our prefix. macOS `path_helper` (/etc/zprofile) runs after
# ~/.zshenv on login shells and pushes Homebrew behind /usr/bin. `homebrew_path`
# is defined in ~/.zshenv; `typeset -U path` keeps this de-duplicated so this is
# just a reorder. Also put Homebrew's completions on fpath before compinit.
path=($homebrew_path $path)
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# Shell Options
setopt autocd # Automatically cd into typed directory.
unsetopt FLOW_CONTROL # Disable ctrl-s to freeze terminal (builtin; no stty fork).
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

# `noexpand` declares an alias that is configuration rather than shorthand, so
# the expansion widget below leaves it alone. Marking it beside the alias keeps
# the two from drifting apart.
_globalias_skip=()
noexpand() { local s; for s in "$@"; do _globalias_skip+=${s%%=*}; alias -- "$s"; done }

[ -f "$ZDOTDIR/aliasrc" ] && source "$ZDOTDIR/aliasrc"

# Bookmark aliases from bm-dirs/bm-files; `(e)` expands their ${XDG_*:-...} forms.
# Each entry also registers a `hash -d` named directory so the key works as a
# path prefix (`~re`, `~cfz`) in any command and abbreviates in the prompt.
() {
  local key rest dir
  if [[ -r "$ZDOTDIR/bm-dirs" ]]; then
    while IFS=$' \t' read -r key rest; do
      [[ -z $key || $key == \#* ]] && continue
      rest=${${rest%%\#*}%%[[:space:]]##}
      dir=${(e)rest}
      alias -- "$key=cd $dir && ll"
      hash -d -- "$key=$dir"
    done < "$ZDOTDIR/bm-dirs"
  fi
  if [[ -r "$ZDOTDIR/bm-files" ]]; then
    while IFS=$' \t' read -r key rest; do
      [[ -z $key || $key == \#* ]] && continue
      rest=${${rest%%\#*}%%[[:space:]]##}
      dir=${(e)rest}
      alias -- "$key=$EDITOR $dir"
      hash -d -- "$key=$dir"
    done < "$ZDOTDIR/bm-files"
  fi
}

# Completions
fpath=("/opt/homebrew/share/zsh-completions" $fpath)

autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
# `compinit -i` rescans every fpath dir and runs compaudit on each start
# (~110ms). Rescan only when the dump is missing or over a day old (~25ms
# otherwise) — new brew/mise completions are picked up within a day, or
# immediately by deleting the dump. The (#qN.mh+24) qualifier needs
# EXTENDED_GLOB, set above.
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_zcompdump:h}" ]] || mkdir -p "${_zcompdump:h}"
_zcompdump_stale=( ${_zcompdump}(#qN.mh+24) )
if [[ ! -s $_zcompdump || ${#_zcompdump_stale} -gt 0 ]]; then
  compinit -i -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump _zcompdump_stale
_comp_options+=(globdots) # Include hidden files.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:descriptions' format '[%d]'
# Colour completion lists by file kind, matching eza's default theme. Set here
# rather than through LS_COLORS, which eza also reads and would then override.
zstyle ':completion:*' list-colors \
  'di=1;34' 'ln=36' 'or=31' 'ex=1;32' 'pi=33' 'so=1;31' 'bd=1;33' 'cd=1;33'

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

# Expand aliases in place on Space and Enter, so $HISTFILE gets the real command.
# Keep aliases flat: `_expand_alias` resolves one level and cannot be looped.
_globalias_expand() {
  [[ $LBUFFER == *[[:alnum:]] ]] || return
  local word=${${(Az)LBUFFER}[-1]}
  (( $_globalias_skip[(Ie)$word] )) && return
  zle _expand_alias
}
globalias()        { _globalias_expand; zle self-insert }
globalias-accept() { _globalias_expand; zle accept-line }
zle -N globalias
zle -N globalias-accept
bindkey -M viins ' '  globalias
bindkey -M viins '^ ' magic-space       # Ctrl-Space = literal space; terminals
bindkey -M viins '^@' magic-space       # send it as either ^ space or NUL
bindkey -M viins '^M' globalias-accept
bindkey -M vicmd '^M' globalias-accept

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

# Suggest from history first, then fall back to the completion system. The
# plugin defaults to (history) alone, which can only ever replay a line typed
# before; `completion` also suggests paths, flags, branches and mise tasks that
# have no history entry. It is ~10000x costlier (it forks a zpty vs. one lookup
# in $history), but it only runs when history misses, and async is on by
# default for zsh >= 5.0.8 so the work never blocks a keystroke.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
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
