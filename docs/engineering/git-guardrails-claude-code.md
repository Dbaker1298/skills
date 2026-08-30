## What it does

`git-guardrails-claude-code` installs a Claude Code `PreToolUse` hook that blocks destructive git commands before the agent runs them: `git push` in every variant, `git reset --hard`, `git clean -f`, `git branch -D`, and `git checkout .` / `git restore .`. It copies a small bash script into `.claude/hooks/`, wires it into the settings file at the scope you choose, and proves it bites before it finishes.

The hook blocks rather than asks. A permission prompt puts the decision in front of you at the moment you are least able to judge it, mid-run and wanting to say yes; this exits non-zero and hands the agent a message saying it does not have the authority, so the destructive path is simply closed and the agent routes around it. Pushing becomes something only you do.

## When to reach for it

Type `/git-guardrails-claude-code`, or the agent reaches for it on its own when you ask to block destructive git operations or add git safety hooks.

- Reach for it when an agent works unattended in a repo where a bad `git push` or `reset --hard` costs real time: a shared branch, a repo without reflog discipline, a long-running background session you are not watching.
- Reach for it before you need it. The failure it prevents is not recoverable by asking the agent to be more careful.

## Prerequisites

Claude Code, and `jq` on `PATH`. The hook script parses the tool call with `jq` and silently lets everything through if it is missing, so a machine without it gets a hook that blocks nothing.

Hooks are a Claude Code mechanism, so this skill does nothing for another **harness**. It is the one skill in `engineering/` that is harness-specific, which its name says out loud.

## The blocked list, and what it does not cover

The script holds a flat list of patterns and greps the whole command against each one. That has two consequences worth knowing before you rely on it.

| Shape | What happens |
| --- | --- |
| `git push`, `git push --force`, `git reset --hard HEAD~3` | Blocked, exit code 2, with a message naming the pattern it matched |
| `git commit --amend`, `git rebase`, `git stash drop`, `git filter-branch` | Not blocked. They are not on the list |
| `echo "run git push later"` | Blocked. The match is a substring of the command, not a parse of it |
| A git operation through something other than the Bash tool | Not blocked. The hook matches `Bash` only |

The list is meant to be edited: step 4 of the skill asks which patterns you want added or removed, and the script is yours once it is copied. Treat the shipped list as a starting position rather than a security boundary.

## Common questions

**Does this stop me pushing too?**
It stops the agent, and you go through the same Bash tool when you ask the agent to push, so in practice yes. Push from your own terminal, which the hook never sees. That split is the point: the guardrail is on the autonomous path, not on you.

**Project scope or global?**
Project scope (`.claude/settings.json`) is the safer default, since it travels with the repo that needs it and leaves your other work alone. Global (`~/.claude/settings.json`) is right when the risk is your habit rather than one repo, but remember it then applies to repos where a blocked `git push` is merely annoying.

**Will the agent understand why it failed?**
Yes. The block is not a silent non-zero: the script writes `BLOCKED: '<command>' matches dangerous pattern '<pattern>'. The user has prevented you from doing this.` to stderr, and the agent reads it and stops trying. Without that sentence an agent tends to retry the same command with different flags.

**It is blocking a command I need.**
Edit the copied script, not the skill. The patterns live in a `DANGEROUS_PATTERNS` array at the top of `.claude/hooks/block-dangerous-git.sh`, and removing a line is the whole fix. The copy is deliberately yours; nothing re-syncs it.

## It's working if

- Asking the agent to push gets you a refusal that quotes the blocked command, not a push.
- The verification command from the last step exits 2 and prints a `BLOCKED` line.
- The agent stops after one refusal instead of retrying the same operation with different flags.
- Ordinary git work (`status`, `add`, `commit`, `log`, `diff`) is untouched.

## Where it fits

A **run-once setup** per repo, or per machine, standalone: nothing chains into it and it chains into nothing.

Its neighbour is [implement](./implement.md), which is the skill that commits your work and therefore the one most likely to reach for a git command you did not intend. Guardrails and `implement` are the two halves of letting an agent touch your history at all: one does the work, the other bounds the blast radius. [setup-david-baker-skills](./setup-david-baker-skills.md) is the other run-once setup here, but they are unrelated in substance; that one configures where issues live, this one configures what the agent may not do.
