# Personal Guidelines

## Pull Requests

- Before making changes in any repository,
  check for `CONTRIBUTING.md` (at the repo root or under `.github/`)
  and follow its guidelines.
- Follow the repo's PR template when one exists,
  typically `.github/PULL_REQUEST_TEMPLATE.md`.
- Always open pull requests as drafts (`gh pr create --draft`).
  Mark a PR ready for review only when I ask.
- Keep PR bodies terse:
  fill the template's sections concisely,
  explain *why*, not *what*,
  and don't restate the diff or the linked issue.
  Keep it to about 10 lines
  and skip "Review focus"-style sections
  unless the template requires them,
  and spell out acronyms.
  Never paste test output; say what is covered instead.
- Keep PRs under about 400 changed lines,
  or explain in the body why the change can't be split.
- When pushing new commits to a branch with an open PR,
  check whether the PR body still describes the changes accurately.
  Update it only if the new commits materially change what the PR does.
- Disclose AI-written PR prose per [AI Disclosure](#ai-disclosure).

## Commit Conventions

Conventional commits.

- **Commit messages**: `type(scope): description`
- **PR titles**: `type(scope): description`
- **Branch names**: `type/short-description`
- **Issue titles**: plain descriptive titles (no conventional commit format)

Use whichever of the standard types fits the change:

| Type | Use for |
| --- | --- |
| `feat` | a new feature |
| `fix` | a bug fix |
| `docs` | documentation only |
| `style` | formatting with no change in behaviour |
| `refactor` | a change that neither fixes a bug nor adds a feature |
| `perf` | a change that improves performance |
| `test` | adding or correcting tests |
| `build` | the build system or dependencies |
| `ci` | CI configuration and scripts |
| `chore` | anything else that touches no source or test files |
| `revert` | reverting an earlier commit |

Add `!` before the colon to flag a breaking change (`feat(api)!: ...`).

## AI Disclosure

When AI contributes GitHub prose —
PR descriptions, reviews, comments, discussion posts —
append this as the last line:

`*AI-assisted — Tool: <tool>; model: <provider>/<model>; version: <version>.*`

Per *piece of prose*, not per operation.
A multi-comment review needs the line on the review body
**and** on each inline comment —
every comment is independently visible
in notification emails and the Files-changed view,
so a reader of one thread must see it there.
Same for a batch of issue comments or several PRs in one turn.

- **Tool** — harness name: `Claude Code`, `Codex`.
- **Model** — what the harness reports for the session,
  verbatim after the `anthropic/` prefix,
  suffixes such as `[1m]` included —
  never tidied into a canonical API id.
- **Version** — the harness's `--version`, leading field only
  (`claude --version` → `2.1.195 (Claude Code)` → `2.1.195`).

Run the version command rather than recalling it,
and write `unavailable` only if that actually fails.

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

Install binaries from GitHub releases with `mise use`
(`-g` outside a project), which records the pin itself;
don't fetch them with `gh release download` or hand-edit tool pins.

## Shell Script Style

In shell scripts and functions committed to a repo,
always use full-length flags (`--type file`, not `-t f`).
Short flags are harder to read at a glance.
This does not apply to throwaway commands run in a terminal.

## Comments and Names

Code describes the system as it is now.
Comments and identifiers must not narrate migration history
or name retired systems, routes or behaviour —
no "kept for compatibility with the old service",
no `legacy…` names for what is now the only path.
That context goes in the commit message and PR body.
Choose names that make sense to a reader who never saw the old design.

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

## Worktrees

When a worktree is called for,
put it in the repo's `.claude/worktrees/`
or, for throwaway checkouts, `$TMPDIR` —
never as a `../<repo>-<suffix>` sibling.

- Session work: `EnterWorktree`.
- Parallel subagents: the Agent tool's `isolation: "worktree"`.
- Throwaway checkouts (e.g. `origin/main` for a lint comparison):
  `git worktree add --detach $TMPDIR/<name> origin/<default-branch>`,
  then `git worktree remove` it when done.

## Workflow

### Circuit Breaker

If the first fix attempt fails or produces unexpected results,
re-read the error output and reconsider the root cause before retrying.
After two failed attempts at the same problem, **stop**.
State what was tried, what failed, and ask for direction.
Do not silently iterate.

### Sync and Branch

Before starting any work, sync with remote (`git fetch origin`)
so you're working on an up-to-date codebase.
In shared repos, never commit directly to main —
always create a branch first.

### Prefer Cloning Over Repeated `gh api` Calls

When you need to examine a repo's contents (README, source, docs),
clone it to `~/repos/` rather than using `gh api` or `gh repo view` repeatedly.
Cloning once lets you read files directly
instead of making a separate call for each one.
Clone it yourself (`gh repo clone org/repo ~/repos/repo`) —
do not ask me to do it.

### Investigation & Research

Before answering questions about repo behavior, configs,
or tool internals (renovate, pitchfork, mise, hk, launchd),
investigate the actual source/config in the repo
rather than answering from general knowledge.
Empirically verify claims before stating them confidently.
