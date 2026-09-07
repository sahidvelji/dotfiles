## Contributing & PR Guidelines

- Before making changes in any repository, check for `CONTRIBUTING.md` (at repo root or under `.github/`) and follow its guidelines.
- When creating pull requests, follow the repo's PR template, typically found at `.github/PULL_REQUEST_TEMPLATE.md`. If a template exists, use its structure and follow its instructions.
- When pushing new commits to a branch with an open PR, check whether the PR body still accurately describes the changes. Update it only if the new commits materially change what the PR does.
- Open PRs as **draft** until they are ready for review. Only mark as "Ready for review" when all checks pass and the work is complete.

## PR & Commit Conventions

Always use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/).

Types: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`

- **Commit messages**: `type(scope): description`
- **PR titles**: `type(scope): description`
- **Branch names**: `type/short-description`
- **Issue titles**: plain descriptive titles (no conventional commit format)

## Task Runners

**mise-first**: Check for `mise.toml`, `.mise.toml`, or `mise/config.toml` in the project (plus global tasks under `~/.config/mise/tasks/`). Run `mise tasks` to discover what's available — it lists each task's name and one-line description, so treat it as a menu of ready-made operations. Prefer `mise run <task>` over hand-rolling a command whenever a task fits — not just build/test/lint/format/check, but domain operations too. Use `mise run <task> --help` to see a task's flags/arguments before running it. For tasks that emit large output (logs, dumps), send it to a file (a `-o/--out` flag if the task has one, else `> file`) and grep the file rather than inlining everything.

If no mise config exists, use whatever task runner the project defines (Makefile, npm scripts, etc.).

Never run raw `go test`, `pytest`, `golangci-lint`, etc. directly when a task runner wraps them — the wrapper may set required env vars, flags, or paths.

## Binary Installation

- Prefer `mise use` for installing binaries from GitHub releases
- Do not use `gh release download` directly or edit `mise.toml` manually

## Shell Script Style

- Always use full-length flags in shell scripts and functions (`--type file` not `-t f`, `--max-depth` not `-d`). Short flags are harder to read at a glance.

## Markdown Style

When authoring or editing prose markdown checked into a repo,
use [semantic line breaks](https://sembr.org)
(READMEs, design docs, in-repo notes, commit message bodies).

**Skip semantic line breaks for GitHub-rendered surfaces:**
issue bodies, PR descriptions, issue/PR comments, discussions, gist text.
Use natural prose paragraphs instead.
GitHub's edit boxes and source views render fragmented lines as ugly,
and the rendered output is the same either way.

Per the [SemBr spec](https://github.com/sembr/specification):

- **MUST** break after a sentence (`.`, `!`, `?`).
- **SHOULD** break after an independent clause (`,`, `;`, `:`, `—`).
- **MAY** break after a dependent clause to clarify structure or fit line length.
- **RECOMMENDED** to break before an enumerated or itemized list.
- **MUST NOT** break inside a hyphenated word.
- A semantic line break **MUST NOT** alter the rendered output.
- Maximum line length of 80 characters is **RECOMMENDED**;
  lines may exceed it to accommodate hyperlinks, code, or other markup.

Skip semantic line breaks inside tables and fenced code blocks.

When in doubt, prefer fewer breaks.
The goal is readable paragraphs, not maximum fragmentation;
SHOULD breaks are judgment calls, not requirements.

When reviewing diffs of semantic-line-break prose,
use `git diff --word-diff` —
default line-mode diffs obscure within-sentence edits.
