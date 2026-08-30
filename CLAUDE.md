# Repository conventions

This is the repository's own instruction file. `AGENTS.md` is a symlink to it, so one edit covers both names and there is nothing to keep in sync.

`CONTEXT.md` holds the glossary. Terms in bold below are defined there; use them rather than the synonyms it lists under `_Avoid_`.

## Buckets

Skills are organised into **bucket** folders under `skills/`:

- `engineering/`: daily code work
- `productivity/`: daily non-code workflow tools
- `misc/`: kept around but rarely used, not promoted
- `in-progress/`: beta: public on purpose, feedback wanted, not shipped in the plugin
- `deprecated/`: no longer used

`engineering/` and `productivity/` are the **promoted** buckets. The Claude Code plugin ships exactly the promoted set.

## Wiring a promoted skill

A promoted skill is **wired** into four places, and all four must agree:

- an entry in `.claude-plugin/plugin.json`'s `skills` array
- an entry in the top-level `README.md`, linking the skill name to its `SKILL.md`
- an entry in its bucket `README.md`, linking the skill name to its `SKILL.md`
- a **docs page** at `docs/<bucket>/<skill-name>.md`

A manifest entry must resolve to a directory that exists, and a directory is not a skill until it holds a `SKILL.md`. A docs page with no promoted skill behind it is an orphan, and goes with the skill it documented. Skills in `misc/`, `in-progress/`, and `deprecated/` appear in none of the four.

Each bucket folder has a `README.md` listing every skill in the bucket with a one-line description, the name linked to its `SKILL.md`. The promoted buckets' `README.md`s and the top-level `README.md` group entries into **User-invoked** and **Model-invoked**; the non-promoted bucket `README.md`s (`misc/`, `in-progress/`) use a flat list.

## Docs pages

The docs tree mirrors the two promoted buckets, and that is all the path means: it is repository organisation, not an address. When you add, rename, or change the behaviour of a promoted skill, create or re-sync its page following [.agents/writing-docs.md](./.agents/writing-docs.md). A finished page carries four sections: **What it does**, **When to reach for it**, **Common questions**, and **It's working if**. `writing-docs.md` holds the template, the section order, and where to hunt for the questions. Pages carry no install commands. Skills in the non-promoted buckets get **no** docs page.

`docs/agents/` is not part of that tree. It holds this repository's own setup output (issue tracker, triage labels, domain layout) rather than skill documentation, so nothing there needs a skill behind it.

## Invocation

Every `SKILL.md` is either user-invoked (`disable-model-invocation: true` plus `policy.allow_implicit_invocation: false` in `agents/openai.yaml`, reachable only by the human) or model-invoked (model- or user-reachable). A skill is user-invoked in every **harness** or in none. See [.agents/invocation.md](./.agents/invocation.md).

## Install commands

Install commands are copied verbatim from the **canonical install blocks** in [.agents/install-block.md](./.agents/install-block.md). Change a block first and propagate outward; never edit a command at a leaf. `.claude-plugin/marketplace.json` makes the repo its own single-plugin marketplace, which is the documented install route: this repo is not in Claude Code's official marketplace, so there is no listing for it to be a fallback to. Why a Claude plugin but not (yet) a Codex one lives in [.agents/adr/0002-ship-as-a-claude-code-plugin.md](./.agents/adr/0002-ship-as-a-claude-code-plugin.md). After changing a block, re-run the sandbox check in [.agents/install-verification.md](./.agents/install-verification.md): install wording is only true once a stranger's copy of the command has been run from outside this repo.

The two manifests are validated by two different commands, and neither covers both:

- `claude plugin validate . --strict` validates `.claude-plugin/marketplace.json` and, through it, the fields of each plugin manifest the marketplace lists. It reports those under a `plugins[<n>] plugin.json` prefix. What it does not do is the per-plugin checks below.
- `claude plugin validate .claude-plugin/plugin.json --strict` validates the plugin manifest directly, and additionally checks the plugin root, which the marketplace run does not.

Run both; the **checker** does, so running it is the shorter way. The plugin-manifest run reports one warning, that `CLAUDE.md` at the plugin root is not loaded as project context, which is accurate and expected: this file is the repository's own instructions and is not shipped to consumers. Under `--strict` that warning fails the run, so the checker suppresses that one finding and fails on any other.

## The checker

`scripts/check.sh` is the **checker**: it checks the structural invariants above, the ones stated here in prose that nothing else enforces. Run it before pushing, and after anything that adds, removes, renames, promotes, or demotes a skill. It reads and reports only, it reports every violation it finds in one run rather than stopping at the first, and it exits non-zero when it finds any. A check that cannot run because the machine lacks a tool reports itself skipped rather than passing quietly; `CHECK_REQUIRE_ALL=1` turns any skip into a failure, which is what CI wants.

Rules are added alongside the work that makes them checkable, so it starts small and grows. What it enforces today is a subset of what this file states: a rule's absence is not permission.

## Local linking

To (re)link the promoted skills into this repo's own harness skill directories (`.claude/skills`, `.agents/skills`, both gitignored), run `scripts/link-skills.sh`. The links are scoped to this repo rather than to `$HOME` on purpose: this repo edits the skills themselves, so a machine-wide install would mean editing a skill silently changes how every other project on the machine behaves. The promoted set is read from `.claude-plugin/plugin.json`, so the non-promoted buckets are never linked. Each entry is a symlink into this repo, so edits take effect immediately; re-run the script after adding, removing, or renaming a skill, and it prunes links whose skill has been dropped or demoted.

## Prose

No em-dashes anywhere in this repo's prose (`SKILL.md` files, docs, `README.md`, ADRs, code comments). Where a sentence reaches for one, rewrite it instead with a comma, colon, period, parentheses, or a conjunction, whichever the sentence actually wants; never do a blind character substitution.

This repository was **seeded** from `mattpocock/skills` and has independent history, so never describe it as a fork, or as forked from or descended from upstream. `UPSTREAM.md` states the relationship; provenance also lives in `LICENSE` and one `README.md` sentence, and those three stay.

Inherited documents that record upstream's reasoning, the ADRs in `.agents/adr/`, are kept in their original voice rather than rewritten into mine. Where one states something that is false here, annotate it; do not edit the reasoning.

## Commits

Commit subjects follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `<type>: <subject>`, or `<type>(<scope>): <subject>` where a scope earns its keep. The types in use here are `feat`, `fix`, `docs`, `refactor`, `chore`, and `test`. Most work in this repository is prose, so `docs` is the common case and a skill's behaviour changing is `feat` or `fix` rather than `docs`, even though the file it lives in is Markdown.

The subject is imperative, lowercase after the type, and carries no trailing period. The body explains why, wraps at roughly 72 columns, and follows the same prose rules as everything else here, em-dashes included. Close the issue the work came from with a `Closes #<n>` line at the end.

Merge commits keep the `Merge #<n>: <subject>` form they already use. They record an integration rather than a change, so the convention does not reach them.

The **checker** does not read commit messages, so nothing enforces this automatically. A `commit-msg` hook would, and adding one is its own decision, not something this section presumes.

## Agent skills

### Issue tracker

Issues live in this repo's GitHub Issues (`Dbaker1298/skills`), via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` at the repo root, ADRs in `.agents/adr/`. See `docs/agents/domain.md`.
