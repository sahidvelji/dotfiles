# Color Defaults
noexpand \
  ls="eza --git --git-repos" \
  grep="grep --color=auto"

# ls Shorthand
noexpand \
  ll="ls --all --long" \
  l="ls --all"

# Safety Defaults
noexpand \
  df="df -h" \
  cp="cp -iv" \
  mv="mv -iv" \
  rmd="rmdir -v" \
  rm="rm -vI" \
  mkd="mkdir -pv"

# Tool Defaults
noexpand \
  bc="bc -ql"

# General Shortcuts
alias \
  ..="cd .. && ll" \
  j="jobs" \
  e="exit" \
  ka="killall" \
  ff="fastfetch" \
  m="mise" \
  mr="mise run" \
  rt="mise run repos-tidy" \
  py="python3" \
  space="du -hd 1 . | sort -h" \
  v="$EDITOR"

# gh Aliases
alias \
  ghw="gh repo view -w" \
  ghcr="gh repo create" \
  ghic="gh issue create" \
  ghpc="gh pr create"

# git Aliases
alias \
  g="git" \
  gl="git log" \
  gp="git push" \
  gs="git status" \
  gd="git diff" \
  gu="git pull" \
  grs="git restore --staged :/ && git status" \
  ga="git add -A"

# Tool Aliases
alias b="bat"
alias c="claude"
alias ch="claude-history"

# Functions

# Yazi cd-on-exit: q quits and cds to last dir, Q quits without cd
f() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  command rm -f -- "$tmp" # bypass the rm alias, whose -v echoes the path
}

# Lazygit cd-on-exit, following repo and worktree switches: q quits and cds, Q quits without cd
lg() {
  local tmp="$(mktemp -t "lazygit-cwd.XXXXXX")" cwd
  LAZYGIT_NEW_DIR_FILE="$tmp" lazygit "$@"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  command rm -f -- "$tmp"
}

cpf() { cp "$@" && cd "$_" && ll; }
mvf() { mv "$@" && cd "$_" && ll; }

ghc() {
  local url="${1:-$(pbpaste)}"
  local repo_name
  # Let gh parse it: handles owner/repo, bare names, SSH and .git URLs, and
  # returns the canonical name if the repo was renamed.
  repo_name="$(gh repo view "$url" --json name --jq .name)" || return
  gh repo clone "$url" "$HOME/repos/$repo_name" -- "${@:2}" &&
    cd "$HOME/repos/$repo_name"
}

ghf() {
  local upstream
  upstream="$(gh repo view --json nameWithOwner --jq .nameWithOwner)" || return
  gh repo fork --remote=true --default-branch-only &&
    gh repo set-default "$upstream"
}

se() {
  local script
  script="$(fd --max-depth 1 --type file --type symlink --base-directory ~/.local/bin | fzf --preview 'bat --color=always ~/.local/bin/{}')"
  [ -n "$script" ] && $EDITOR "$HOME/.local/bin/$script"
}

s() {
  local dir
  local base_path="$HOME/repos"
  dir=$(fd --max-depth 1 --type d --hidden --base-directory "$base_path" | fzf --ansi \
    --header 'ctrl-o: open in browser | enter: cd into repo' \
    --bind 'ctrl-o:execute-silent(cd '"$base_path"'/{} && gh repo view --web)+abort') &&
    cd "$base_path/$dir" && ll && gs
}

# Check out a pull request and hand it to Claude for review. Takes anything
# `gh pr view` accepts (URL, number inside a repo); falls back to the clipboard.
# Always uses the repo the PR targets, never the fork: `gh pr checkout` fetches
# the head ref (refs/pull/N/head) through the API, so a fork is never cloned or
# added as a remote even for a cross-fork PR.
#
# The review runs in a detached worktree at <clone>/.claude/worktrees/pr-N, so
# the clone's own checkout is never touched and no local branch is claimed: git
# lets a branch live in only one worktree, so checking out the PR's branch fails
# whenever another worktree already holds it. `repos-tidy` removes the worktree
# once the PR is no longer open.
review-pr() {
  local input="${1:-$(pbpaste)}"
  [ -n "$input" ] || {
    print -u2 "review-pr: no PR given and the clipboard is empty"
    return 1
  }

  # gh normalizes any accepted form to the base repo's canonical URL,
  # https://github.com/OWNER/REPO/pull/N — so OWNER/REPO is the base even for a
  # cross-fork PR. There is no baseRepository JSON field, hence deriving it from
  # the URL. Captured before the read: read's own status would mask a gh failure.
  local out
  out="$(gh pr view "$input" --json url,number \
    --jq '"\(.url | sub("https://github.com/";"") | sub("/pull/.*";"")) \(.number)"')" || return
  local owner_repo number
  read -r owner_repo number <<<"$out"
  local repo="${owner_repo#*/}"

  local dir="$HOME/repos/$repo"
  [ -d "$dir" ] || gh repo clone "$owner_repo" "$dir" || return
  # ~/repos is keyed by repo name alone, so an existing clone may belong to a
  # same-named repo under another owner. Any remote counts: on a fork clone the
  # base repo is `upstream`, not origin.
  git -C "$dir" remote --verbose |
    grep --quiet --ignore-case --extended-regexp \
      "github\.com[:/]${owner_repo//./\\.}(\.git)?[[:space:]]" || {
    print -u2 "review-pr: $dir has no remote for $owner_repo"
    return 1
  }
  cd "$dir" || return

  # A worktree whose directory was deleted stays registered and blocks re-adding
  # it. An existing pr-N worktree is updated in place, keeping uncommitted
  # edits, but only while it sits at the reviewed commit: moving HEAD would
  # strand commits made there since.
  local wt="$dir/.claude/worktrees/pr-$number" record reviewed
  git worktree prune
  if [ -d "$wt" ]; then
    record="$(git -C "$wt" rev-parse --absolute-git-dir)/review-pr-repo"
    [ -f "$record" ] || {
      print -u2 "review-pr: $wt has no review-pr record; check it, then: git -C $dir worktree remove $wt"
      return 1
    }
    read -r _ reviewed <"$record"
    [[ "$(git -C "$wt" rev-parse HEAD)" == "$reviewed" ]] || {
      print -u2 "review-pr: $wt has moved off the reviewed commit; save or discard that work first"
      return 1
    }
  fi
  gh pr checkout "$number" --repo "$owner_repo" --detach --worktree "$wt" || return
  cd "$wt" || return
  # Bare PR numbers resolve against gh's default repo for the clone, which on a
  # multi-remote clone need not be $owner_repo, so repos-tidy reads the repo
  # from this record, along with the reviewed commit. It lives in the
  # worktree's git dir, so it goes away with the worktree.
  print -r -- "$owner_repo $(git rev-parse HEAD)" >"$(git rev-parse --absolute-git-dir)/review-pr-repo" || return
  # The session name becomes the terminal title, telling parallel reviews apart.
  claude --name "review $repo#$number" \
    "/code-review xhigh https://github.com/$owner_repo/pull/$number"
}
alias rp="review-pr"
