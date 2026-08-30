# Verifying the install routes

The commands in [install-block.md](./install-block.md) are the first thing a
stranger runs, so they are checked from a **consumer sandbox**: a throwaway
project outside this repository, with its own Claude Code config directory. Run
from inside the repository they would pass on files that are already there,
which proves nothing.

Re-run this after changing either canonical block, and after the repository
goes public.

## The sandbox

Two kinds of isolation matter. `CLAUDE_CONFIG_DIR` keeps the marketplace clone
and the plugin cache out of `~/.claude`, and `--scope project` keeps the
marketplace and plugin declarations in the sandbox project's own settings. With
both, nothing the check installs can change how any other project on this
machine behaves.

```sh
export CLAUDE_CONFIG_DIR=/tmp/skills-consumer-sandbox/claude-config
mkdir -p "$CLAUDE_CONFIG_DIR" /tmp/skills-consumer-sandbox/project
cd /tmp/skills-consumer-sandbox/project && git init -q
```

Delete `/tmp/skills-consumer-sandbox` when done. Nothing in it is worth keeping.

## Route 1: the Claude Code plugin

```sh
claude plugin marketplace add Dbaker1298/skills --scope project
claude plugin install david-baker-skills@dbaker1298 --scope project -y
claude plugin details david-baker-skills
```

`-y` is required because the check runs without a TTY; a human at a terminal
gets the confirmation prompt instead, and does not pass it.

The installed set must be the **promoted** set exactly. Compare the names in the
component inventory against the manifest rather than eyeballing them:

```sh
claude plugin details david-baker-skills |
  sed -n '/Skills (/p' | sed 's/.*Skills ([0-9]*)//' |
  tr ',' '\n' | tr -d ' ' | grep -v '^$' | sort > /tmp/installed.txt
grep -o '"\./skills/[^"]*"' <repo>/.claude-plugin/plugin.json |
  tr -d '"' | xargs -n1 basename | sort > /tmp/promoted.txt
diff /tmp/installed.txt /tmp/promoted.txt
```

Then invoke an installed skill, allowing only the Skill tool so the answer can
only have come from the installed copy:

```sh
claude -p "Invoke the codebase-design skill, then answer only this from it: \
what one-sentence definition does its glossary give for the term Depth?" \
  --allowedTools "Skill"
```

## Route 2: skills.sh

```sh
npx --yes skills@latest add Dbaker1298/skills
```

Then read `skills-lock.json` and `.agents/skills/` for what actually landed.

## Results, 2026-08-29

Run against `31f6180`, from `/tmp/skills-consumer-sandbox/project`.

| Check | Result |
| --- | --- |
| Marketplace adds by GitHub slug | Passed. Cloned `git@github.com:Dbaker1298/skills.git`, validated, declared in project settings as `dbaker1298` |
| Plugin installs from it | Passed. `david-baker-skills@dbaker1298` 0.1.0, enabled, project scope |
| Installed set is the promoted set | Passed. 24 skills, exact match against the manifest, nothing from `in-progress/` or `misc/` |
| An installed skill is invoked | Passed. `codebase-design` fired through the Skill tool and returned its glossary definition of **depth** verbatim, with only the Skill tool allowed |
| skills.sh installs | Ran, but see the finding below |
| Host machine untouched | Passed. `~/.claude/plugins` still does not exist |

**Finding: skills.sh serves the whole `skills/` tree.** It installed 36 skills,
the 24 promoted ones plus all 12 from `in-progress/` and `misc/`, because it
reads the repository's directories rather than the plugin manifest. Two things
follow, and the whole-set canonical block now says both: the menu a human sees
lists skills this repository does not stand behind, and a piped run takes every
one of them without asking. The promoted set is a guarantee of the plugin route
only.

**Since corrected, 2026-08-30.** The tree the run measured has changed, so the
two counts above are historical rather than current. #37 dropped six skills and
removed `misc/` as a bucket, promoting `git-guardrails-claude-code` into
`engineering/`. The promoted set is 25, the non-promoted remainder is 4, all of
them in `in-progress/`, and a whole-tree skills.sh run would now take 29. The
finding itself is unaffected: skills.sh still reads directories rather than the
manifest, which is the part that has to be re-checked, not the arithmetic.

**Not proved: public reachability.** Both routes succeeded while the repository
is private, because both authenticate as me, the plugin route over SSH and
skills.sh through my GitHub credentials. Unauthenticated, `skills.sh` and the
GitHub API both answer 404 for this repository. So this run proved the
manifests, the wording, and the installed set, and left the stranger's position
untested.

## The anonymous re-run

Both routes have to be checked from a position with no credentials, which is
harder to reach than it looks.

Do not reach for `gh auth logout`: logging the machine out to test a clone is a
large change to make for a small check, and it is easy to forget to undo.
Emptying `HOME` is the right instinct and is not enough on its own. On this
machine, `env -i HOME=<empty dir> ssh -T git@github.com` still answers
`Hi Dbaker1298!`, so an SSH clone keeps succeeding as me with no `~/.ssh` in
sight. A check that only empties `HOME` proves nothing about the plugin route.

What works is to break SSH outright and make the fallback do the work:

```sh
export SANDBOX_HOME=/tmp/skills-anon-sandbox/home
mkdir -p "$SANDBOX_HOME" /tmp/skills-anon-sandbox/project
cd /tmp/skills-anon-sandbox/project && git init -q

anon() {
  env -i HOME="$SANDBOX_HOME" PATH="$PATH" \
    GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND=/bin/false \
    CLAUDE_CONFIG_DIR="$SANDBOX_HOME/claude" "$@"
}

anon claude plugin marketplace add Dbaker1298/skills --scope project
anon claude plugin install david-baker-skills@dbaker1298 --scope project -y
anon npx --yes skills@latest add Dbaker1298/skills --skill wait-what --agent '*' -y
```

`GIT_SSH_COMMAND=/bin/false` makes every SSH attempt fail, so a route that
still succeeds can only have reached the repository anonymously over HTTPS.
`GIT_TERMINAL_PROMPT=0` stops a credential prompt turning a red check into a
hung one. Neither variable touches anything outside the command it prefixes.

## Results, 2026-08-30

Repository flipped to public. Run against `b146b33`, from
`/tmp/skills-anon-sandbox/`, under the `anon` prefix above.

| Check | Result |
| --- | --- |
| Anonymous HTTPS clone | Passed. `git clone https://github.com/Dbaker1298/skills.git` with no credentials reachable |
| Plugin route falls back to HTTPS | Passed. `SSH clone failed, retrying with HTTPS`, then cloned and validated the marketplace |
| Plugin installs anonymously | Passed. `david-baker-skills@dbaker1298` 0.1.0, project scope |
| Installed set is the promoted set | Passed. 25 skills, exact match against the manifest |
| A promoted skill is invoked | Passed. `git-guardrails-claude-code`, promoted the day before, listed its five blocked command shapes with only the Skill tool allowed |
| skills.sh resolves the public repository | Passed. Enumerated 29 skills and installed `wait-what` alone into `.agents/skills/` |
| `github.com/Dbaker1298/skills` anonymously | 200 |
| `skills.sh/Dbaker1298/skills` anonymously | 404, see below |

**Finding: `--skill=<name>` is accepted and ignored.** The single-skill block
used the `=` spelling. Passed that way with `-y`, the installer skips no menu
and installs **all 29 skills**, which is the opposite of what the reader asked
for. `--skill <name>` with a space works, and wants `--agent '*' -y` beside it
to run without a terminal. Both canonical blocks now use the space form.

**Finding: the skills.sh page for this repository 404s.** The URL shape is
right, since `skills.sh/vercel-labs/agent-skills` answers 200, so this
repository is simply not indexed yet. The CLI route works regardless, because
it reads GitHub rather than the site. `README.md` and the block now link
`skills.sh` itself rather than a page that does not exist; restore the deep
link once it resolves.
