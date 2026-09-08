#!/bin/sh
# Claude Code status line — two rows, each capped at MAXW visible columns.
#   row 1: model · dir · git branch[*] · worktree · agent
#   row 2: context % + tokens · 5h/7d quota + reset countdown · cost · branch diff
#
# Width is tracked as an integer while segments are appended, rather than
# measured off the finished string: the rows contain ANSI escapes and
# multi-byte glyphs (· ↻ …), so ${#row} would count neither reliably
# across locales. Each add() call passes the visible column count it costs.
#
# When a row exceeds MAXW, segments are dropped in a fixed priority order
# (see degrade loops below) rather than truncated, so the row stays readable.
#
# Requires: git, jq. Without jq only flat string fields are read.

MAXW=99

json=$(cat)

RESET="\033[0m"; DIM="\033[2m"
CYAN="\033[36m"; BLUE="\033[34m"; YELLOW="\033[33m"
GREEN="\033[32m"; MAGENTA="\033[35m"; RED="\033[31m"; GREY="\033[90m"

if command -v jq >/dev/null 2>&1; then
  # One jq invocation, not fifteen: this runs on every render.
  vals=$(printf '%s' "$json" | jq -r '
    [ (.model.display_name // ""), (.cwd // ""),
      (.agent.name // ""), (.worktree.name // ""),
      (.context_window.used_percentage // ""),
      (.context_window.total_input_tokens // ""),
      (.context_window.context_window_size // ""),
      (.rate_limits.five_hour.used_percentage // ""),
      (.rate_limits.five_hour.resets_at // ""),
      (.rate_limits.seven_day.used_percentage // ""),
      (.rate_limits.seven_day.resets_at // ""),
      (.cost.total_cost_usd // "") ] | .[] | tostring' 2>/dev/null)
  {
    IFS= read -r model_name; IFS= read -r cwd
    IFS= read -r agent_name; IFS= read -r wt_name
    IFS= read -r ctx_pct;    IFS= read -r ctx_tok;  IFS= read -r ctx_max
    IFS= read -r rl_5h;      IFS= read -r rl_5h_reset
    IFS= read -r rl_7d;      IFS= read -r rl_7d_reset
    IFS= read -r cost
  } <<VALS_EOF
$vals
VALS_EOF
else
  model_name=$(printf '%s' "$json" | sed -n 's/.*"display_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
  cwd=$(printf '%s' "$json" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
fi

[ -z "$cwd" ] && cwd="$PWD"

case "$cwd" in
  "$HOME"/*) dir_full="~${cwd#"$HOME"}" ;;
  "$HOME")   dir_full="~" ;;
  *)         dir_full="$cwd" ;;
esac
dir_base=${dir_full##*/}

branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ] && [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
    branch="${branch}*"
  fi

  # Lines changed on this branch: committed work since it diverged from the
  # default branch, plus everything still uncommitted. Counted from git rather
  # than from .cost.total_lines_*, which tracks only what Claude edited via its
  # own tools this session -- blind to shell-driven edits, and reset each run.
  #
  # HEAD is the fallback base when no default branch is found (detached HEAD, a
  # fresh repo, or a clone without one), which reduces this to uncommitted work.
  #
  # `upstream` is tried before `origin` for the fork workflow: when origin is a
  # fork, its default branch trails the real one, and every upstream commit the
  # branch was rebased onto would be counted as local work. In this repo that
  # is the difference between +47 and +3615.
  base=""
  for cand in \
    "$(git -C "$cwd" --no-optional-locks symbolic-ref --quiet --short refs/remotes/upstream/HEAD 2>/dev/null)" \
    upstream/main upstream/master \
    "$(git -C "$cwd" --no-optional-locks symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)" \
    origin/main origin/master main master; do
    [ -n "$cand" ] || continue
    if git -C "$cwd" --no-optional-locks rev-parse --verify --quiet "$cand" >/dev/null 2>&1; then
      base=$(git -C "$cwd" --no-optional-locks merge-base HEAD "$cand" 2>/dev/null) && [ -n "$base" ] && break
    fi
  done
  [ -n "$base" ] || base=HEAD
  # --shortstat prints "N files changed, N insertions(+), N deletions(-)", with
  # either the insertions or the deletions clause absent when that count is 0.
  stat=$(git -C "$cwd" --no-optional-locks diff --shortstat "$base" 2>/dev/null)
  if [ -n "$stat" ]; then
    git_add=$(printf '%s' "$stat" | sed -n 's/.*[^0-9]\([0-9][0-9]*\) insertion.*/\1/p')
    git_del=$(printf '%s' "$stat" | sed -n 's/.*[^0-9]\([0-9][0-9]*\) deletion.*/\1/p')
  fi
fi

int_of() { printf '%.0f' "$1" 2>/dev/null; }
fmt_tokens() {
  case "$1" in ''|*[!0-9]*) return 0 ;; esac
  if   [ "$1" -ge 1000000 ]; then printf '%dM' "$(( $1 / 1000000 ))"
  elif [ "$1" -ge 1000 ];    then printf '%dk' "$(( $1 / 1000 ))"
  else printf '%d' "$1"; fi
}

now=$(date +%s)
# Time remaining until a quota window refills, unit-suffixed so it cannot be
# misread as a wall clock. Largest two units: 4d22h  2h14m  7m  <1m
fmt_reset() {
  [ -n "$1" ] || return 0
  case "$1" in *[!0-9]*) return 0 ;; esac
  delta=$(( $1 - now ))
  [ "$delta" -gt 0 ] || return 0
  d=$(( delta / 86400 )); h=$(( delta % 86400 / 3600 )); m=$(( delta % 3600 / 60 ))
  if   [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then printf '%dm' "$m"
  else printf '<1m'; fi
}

# add <row-var-suffix> <colored text> <visible columns>
add() {
  case "$1" in
    1) [ -n "$row1" ] && { row1="${row1}${DIM} · ${RESET}"; w1=$(( w1 + 3 )); }
       row1="${row1}$2"; w1=$(( w1 + $3 )) ;;
    2) [ -n "$row2" ] && { row2="${row2}${DIM} · ${RESET}"; w2=$(( w2 + 3 )); }
       row2="${row2}$2"; w2=$(( w2 + $3 )) ;;
  esac
}

# ---- row 1 -----------------------------------------------------------------
# Degrade order: worktree -> shorten dir -> drop agent -> trim branch
r1_wt=1; r1_dir=1; r1_agent=1
build_row1() {
  row1=""; w1=0
  [ -n "$model_name" ] && add 1 "${CYAN}${model_name}${RESET}" "${#model_name}"
  if [ "$r1_dir" = 1 ]; then
    add 1 "${BLUE}${dir_full}${RESET}" "${#dir_full}"
  else
    add 1 "${BLUE}…/${dir_base}${RESET}" "$(( ${#dir_base} + 2 ))"
  fi
  [ -n "$branch" ] && add 1 "${YELLOW}${branch}${RESET}" "${#branch}"
  [ -n "$wt_name" ] && [ "$r1_wt" = 1 ] && add 1 "${GREY}wt:${wt_name}${RESET}" "$(( ${#wt_name} + 3 ))"
  [ -n "$agent_name" ] && [ "$r1_agent" = 1 ] && add 1 "${MAGENTA}@${agent_name}${RESET}" "$(( ${#agent_name} + 1 ))"
}
build_row1
[ "$w1" -gt "$MAXW" ] && { r1_wt=0;    build_row1; }
[ "$w1" -gt "$MAXW" ] && { r1_dir=0;   build_row1; }
[ "$w1" -gt "$MAXW" ] && { r1_agent=0; build_row1; }
# Last resort: a pathological branch name. Trim it and rebuild.
if [ "$w1" -gt "$MAXW" ] && [ -n "$branch" ]; then
  keep=$(( ${#branch} - ( w1 - MAXW ) - 1 ))
  [ "$keep" -lt 8 ] && keep=8
  branch="$(printf '%.*s' "$keep" "$branch")…"
  build_row1
fi

# ---- row 2 -----------------------------------------------------------------
# Degrade order: diff -> cost -> token counts -> reset countdowns
r2_diff=1; r2_cost=1; r2_tok=1; r2_reset=1
build_row2() {
  row2=""; w2=0
  if [ -n "$ctx_pct" ]; then
    p=$(int_of "$ctx_pct")
    if [ -n "$p" ]; then
      if   [ "$p" -ge 90 ]; then c="$RED"
      elif [ "$p" -ge 70 ]; then c="$YELLOW"
      else c="$GREEN"; fi
      tok=$(fmt_tokens "$ctx_tok"); max=$(fmt_tokens "$ctx_max")
      if [ "$r2_tok" = 1 ] && [ -n "$tok" ] && [ -n "$max" ]; then
        txt="ctx ${tok}/${max} ${p}%"
      else
        txt="ctx ${p}%"
      fi
      add 2 "${c}${txt}${RESET}" "${#txt}"
    fi
  fi
  for wnd in 5h 7d; do
    if [ "$wnd" = 5h ]; then v="$rl_5h"; rr="$rl_5h_reset"; else v="$rl_7d"; rr="$rl_7d_reset"; fi
    [ -n "$v" ] || continue
    vr=$(int_of "$v"); [ -n "$vr" ] || continue
    txt="${wnd} ${vr}%"; sw=${#txt}
    if [ "$r2_reset" = 1 ]; then
      cd=$(fmt_reset "$rr")
      [ -n "$cd" ] && { txt="${txt} ↻${cd}"; sw=$(( sw + 2 + ${#cd} )); }
    fi
    add 2 "${MAGENTA}${txt}${RESET}" "$sw"
  done
  if [ "$r2_cost" = 1 ] && [ -n "$cost" ]; then
    cs=$(printf '%.2f' "$cost" 2>/dev/null)
    if [ -n "$cs" ] && [ "$cs" != "0.00" ]; then
      add 2 "${GREY}\$${cs}${RESET}" "$(( ${#cs} + 1 ))"
    fi
  fi
  if [ "$r2_diff" = 1 ]; then
    la=${git_add:-0}; ld=${git_del:-0}
    case "$la$ld" in ''|*[!0-9]*) la=0; ld=0 ;; esac
    if [ "$la" -gt 0 ] || [ "$ld" -gt 0 ]; then
      add 2 "${GREEN}+${la}${RESET}${DIM}/${RESET}${RED}-${ld}${RESET}" "$(( ${#la} + ${#ld} + 3 ))"
    fi
  fi
}
build_row2
[ "$w2" -gt "$MAXW" ] && { r2_diff=0;  build_row2; }
[ "$w2" -gt "$MAXW" ] && { r2_cost=0;  build_row2; }
[ "$w2" -gt "$MAXW" ] && { r2_tok=0;   build_row2; }
[ "$w2" -gt "$MAXW" ] && { r2_reset=0; build_row2; }

[ -n "$row1" ] && printf '%b\n' "$row1"
[ -n "$row2" ] && printf '%b\n' "$row2"

# Must exit 0: a non-zero exit blanks the status line entirely. Without this,
# the trailing `[ -n "$row2" ]` test becomes the exit status, so a session with
# no messages yet (no context_window / rate_limits -> empty row 2) would exit 1
# and show nothing until the first assistant message arrived.
exit 0
