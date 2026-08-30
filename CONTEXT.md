# David Baker's Skills

A collection of agent skills: Markdown files, each telling a coding agent how to do one thing well. They are built to be installed into a consuming repository, as a Claude Code plugin or as editable files copied in by skills.sh; per-repo configuration written by `/setup-david-baker-skills` then tells them where issues live and what the labels are called.

## Language

### This repository

**Skill**:
One directory under a **Bucket**, holding a `SKILL.md` that tells an agent how to do one thing. The unit this repository ships.
_Avoid_: command, slash command

**Bucket**:
A folder directly under `skills/` that sorts skills by their standing here: `engineering/` and `productivity/` for daily work, `in-progress/` for beta, `deprecated/` for retired.
_Avoid_: category, group, folder

**Promoted**:
The state of sitting in `engineering/` or `productivity/`. The promoted skills are exactly the set this repository stands behind and ships.
_Avoid_: published, shipped, official, supported

**Wired**:
Of a **Promoted** skill: listed in every place that has to agree about it, the plugin manifest, the top-level `README.md`, its bucket `README.md`, and its **Docs page**.
_Avoid_: registered, linked, hooked up

**Docs page**:
The human-facing page for one **Promoted** skill, at `docs/<bucket>/<skill-name>.md`. Written for a reader deciding whether to use the skill rather than for the agent running it.
_Avoid_: documentation, README

**User-invoked**:
A **Skill** the human can reach and the model cannot, declared as such in the skill's own metadata for every **Harness**.
_Avoid_: manual, explicit

**Model-invoked**:
A **Skill** the agent may reach for on its own when the task fits, as well as the human.
_Avoid_: automatic, implicit, autonomous

**Harness**:
A coding agent that loads skills, such as Claude Code or Codex. Each has its own way of keeping a **User-invoked** skill out of the model's reach, which is why invocation is declared once per harness.
_Avoid_: client, host, runtime

**Checker**:
`scripts/check.sh`, the guard for this repository's structural invariants: the rules stated as prose in `CLAUDE.md` that nothing else enforces.
_Avoid_: linter, validator, CI

**Canonical install block**:
A named region of `.agents/install-block.md` holding the one approved wording for one install route. It is the source; `README.md` holds copies.
_Avoid_: install snippet, install instructions

**Seeded**:
How this repository relates to **Upstream**: files copied at a named commit, under the MIT licence, with git history that begins here.
_Avoid_: fork, forked from, descended from

**Upstream**:
`mattpocock/skills`, the repository this one was **Seeded** from, as it stands today.
_Avoid_: origin, parent, source repo

### What the skills talk about

**Issue tracker**:
The tool that hosts a repo's issues: GitHub Issues, Linear, a local `.scratch/` markdown convention, or similar. Skills like `to-tickets`, `to-spec`, and `triage` read from and write to it.
_Avoid_: backlog manager, backlog backend, issue host

**Issue**:
A single tracked unit of work inside an **Issue tracker**: a bug, task, spec, or slice produced by `to-tickets`.
_Avoid_: ticket (use only when quoting external systems that call them tickets, or for a **Decision ticket**, see below)

**Decision ticket**:
A `wayfinder` unit: a child **Issue** of a `wayfinder:map` holding a *question* whose resolution is a decision, not a slice of a build to execute. The **decision** qualifier is what keeps it distinct from an implementation ticket; `wayfinder` introduces the term, then uses "ticket".

**Triage role**:
A canonical state-machine label applied to an **Issue** during triage, mapped to the tracker's real label string in `docs/agents/triage-labels.md`. There are five: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`.

## Relationships

- A **Bucket** holds many **Skills**; a **Skill** sits in exactly one **Bucket**
- A **Promoted** skill has exactly one **Docs page**; a skill in any other bucket has none
- Every **Skill** is either **User-invoked** or **Model-invoked**, never both
- A **User-invoked** skill may invoke **Model-invoked** skills, but never another **User-invoked** one
- An **Issue tracker** holds many **Issues**
- An **Issue** carries one **Triage role** at a time
- A **Decision ticket** is an **Issue** (a child of a `wayfinder:map`)

## Flagged ambiguities

- "backlog" was previously used to mean both the *tool* hosting issues and the *body of work* inside it. Resolved: the tool is the **Issue tracker**; "backlog" is no longer used as a domain term.
- "backlog backend" / "backlog manager". Resolved: collapsed into **Issue tracker**.
- "fork" was used for this repository's relationship to **Upstream**. Resolved: **Seeded**. The distinction is load-bearing rather than stylistic, because `UPSTREAM.md` denies exactly the ancestry "fork" asserts.
- "skill" also names the installed copy in a consuming repo, which is what skills.sh and the Claude Code plugin write. Resolved: one term, because both senses are the same artifact at two addresses.
