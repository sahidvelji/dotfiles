# Personal Guidelines

## Pull Requests

- Before making changes in any repository,
  check for `CONTRIBUTING.md` (at the repo root or under `.github/`)
  and follow its guidelines.
- Follow the repo's PR template when one exists,
  typically `.github/PULL_REQUEST_TEMPLATE.md`.
- Always open pull requests as drafts (`gh pr create --draft`).
  Mark a PR ready for review only when I ask.
- Keep PR descriptions moderate in length —
  a few short sections covering what changed, why,
  and anything a reviewer genuinely needs to know.
  Section headers are fine.
  Never paste test output; say what is covered instead.
- When pushing new commits to a branch with an open PR,
  check whether the PR body still describes the changes accurately.
  Update it only if the new commits materially change what the PR does.
- Never put a `claude.ai/code/session_...` link in a PR body or a commit message.
  This includes the `Claude-Session:` commit trailer
  and the session URL in the generated-with footer —
  drop those lines entirely.

## Commit Conventions

Conventional commits, using only these types:
`feat`, `fix`, `docs`, `chore`, `test`, `refactor`.

- **Commit messages**: `type(scope): description`
- **PR titles**: `type(scope): description`
- **Branch names**: `type/short-description`
- **Issue titles**: plain descriptive titles (no conventional commit format)

## Task Runners

**mise-first**: check for a mise config
(`mise.toml`, `.mise.toml`, `.config/mise/config.toml`,
plus global tasks under `~/.config/mise/tasks/`)
and run `mise tasks` to see what exists.
Prefer `mise run <task>` over a hand-rolled command whenever a task fits —
domain operations as well as build/test/lint/format/check.
Check `mise run <task> --help` for flags before running.
For tasks that emit large output (logs, dumps),
send it to a file (a `-o/--out` flag if the task has one, else `> file`)
and grep the file rather than inlining everything.

If no mise config exists,
use whatever task runner the project defines (Makefile, npm scripts, etc.).
Never run raw `go test`, `pytest`, `golangci-lint`, etc.
directly when a task runner wraps them —
the wrapper may set required env vars, flags, or paths.

## Binary Installation

Prefer `mise use` for installing binaries from GitHub releases.
Do not use `gh release download` directly or edit `mise.toml` by hand.

## Shell Script Style

In shell scripts and functions committed to a repo,
always use full-length flags (`--type file`, not `-t f`).
Short flags are harder to read at a glance.
This does not apply to throwaway commands run in a terminal.

## Markdown Style

Use [semantic line breaks](https://sembr.org) in prose markdown checked into a repo
(READMEs, design docs, in-repo notes, commit message bodies):
break after every sentence,
and after a major clause boundary where it clarifies structure.
Keep lines under 80 characters where practical,
longer where a link, code, or other markup needs the room.
A break must never change the rendered output
and must never fall inside a hyphenated word.
Skip breaks inside tables and fenced code blocks.
When in doubt prefer fewer breaks —
the goal is readable paragraphs, not maximum fragmentation.

**Do not use semantic line breaks on GitHub-rendered surfaces:**
issue bodies, PR descriptions, issue/PR comments, discussions, gist text.
Use natural prose paragraphs there.
GitHub's edit boxes and source views render fragmented lines as ugly,
and the rendered output is the same either way.

When reviewing diffs of semantic-line-break prose, use `git diff --word-diff`;
default line-mode diffs obscure within-sentence edits.
