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

**Not proved: public reachability.** Both routes succeeded while the repository
is private, because both authenticate as me, the plugin route over SSH and
skills.sh through my GitHub credentials. Unauthenticated, `skills.sh` and the
GitHub API both answer 404 for this repository. So this run proved the
manifests, the wording, and the installed set, and left the stranger's position
untested.

## Still to run, once the repository is public

Re-run both routes with the credentials out of the way, which is the only part
that has to wait: a machine that has never authenticated to GitHub, or a shell
with `GH_TOKEN` unset, `gh auth logout`, and the SSH agent empty. What is being
checked is that the clone falls back to HTTPS and succeeds anonymously, and
that `skills.sh/Dbaker1298/skills` answers 200. Record the result here.
