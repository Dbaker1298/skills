# Ship the skill set as a native Claude Code plugin; defer a native Codex plugin

These skills have always been installable via [skills.sh](https://skills.sh/mattpocock/skills) (`npx skills add mattpocock/skills`), which copies editable skill files into a user's project across Claude Code, Codex, and other Agent-Skills-standard harnesses. A recurring request is a **plug-and-play** distribution: subscribe to the set as a read-only, always-current bundle you don't edit, rather than a fork you own. That is exactly what native plugin systems provide.

We ship a native **Claude Code plugin** and, for now, **defer** a native **Codex plugin**. The split is forced by how each ecosystem's plugin manifest selects skills, against this repo's bucketed layout.

## The constraint: bucketed skills vs. single-path selection

Skills live in bucket folders under `skills/`: `engineering/` and `productivity/` are **promoted** (shipped); `misc/`, `personal/`, `in-progress/`, and `deprecated/` are **not**. A plugin must expose only the promoted set, which spans two of those bucket folders.

- **Claude Code**: `.claude-plugin/plugin.json` accepts `skills` as an **array of explicit skill-directory paths**. We list the promoted skills one by one, exclude everything else with zero ambiguity, and add `.claude-plugin/marketplace.json` so the repo is its own single-plugin marketplace. Verified end to end: `claude plugin validate . --strict` passes, and `marketplace add` → `install` resolves all promoted skills.

- **Codex**: `.codex-plugin/plugin.json` accepts `skills` only as a **single path string** (arrays are rejected with `missing or invalid plugin.json`), and Codex discovers `SKILL.md` files recursively under it. There is no way to name two bucket folders, or to curate a subset, from one path. Two escape hatches were tested and rejected:
  - Pointing at `./skills/` would also ship `deprecated/`, `in-progress/`, `personal/`, and `misc/`: retired, draft, and personal skills we deliberately don't promote.
  - A curated flat directory of **symlinks** into the buckets does not survive install: Codex copies the plugin tree into its cache and **drops symlinks**, so the skills arrive empty.

The only robust ways to give Codex a single promoted-only path are (a) **restructure** so `skills/` contains only promoted skills (moving the non-promoted buckets out, a large blast radius across `CLAUDE.md`, `scripts/link-skills.sh`, the bucket READMEs, and the local dev workflow that relies on `in-progress/` and `personal/`), or (b) **commit duplicate copies** of promoted skills into a flat directory (a sync burden and a second source of truth). Both are structural decisions, not something to bundle into shipping the Claude plugin. This is very likely the original, half-remembered reason a plugin wasn't shipped earlier: the manifest formats didn't cleanly express a curated subset of a bucketed repo.

## Decision

- Ship the **Claude Code plugin** now (`.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`), curated to the promoted set, as the headline v1.2 deliverable.
- Keep **skills.sh** as the universal installer: it already serves Codex and other harnesses today, so no Codex user is left without an install path.
- **Defer** the native Codex plugin until we decide between restructuring `skills/` to promoted-only vs. committing a generated flat copy. Revisit when Codex either supports a `skills` array / include-list or preserves symlinks on install.

## Invariants this creates

- Every promoted skill has an entry in `.claude-plugin/plugin.json`'s `skills` array (this already stood as a `CLAUDE.md` rule; it now also gates the plugin's contents).
- `.claude-plugin/plugin.json`'s `version` tracks `package.json`'s version: bump both together on release. Claude uses the plugin `version` to decide when installed users see an update.

## Update, 2026-08-05

> **This section records upstream's marketplace listing, which this repository
> does not have.** Its install route, its "superseded" verdict, and its
> verification are upstream's and do not carry over. Left in place as their
> evidence; corrected under [Update, 2026-08-29](#update-2026-08-29) below.

`mattpocock-skills` was accepted into **Claude Code's official marketplace** (configured name `claude-plugins-official`, source repo `anthropics/claude-plugins-official`), which every Claude Code install has by default. `claude plugins install mattpocock-skills` is now the documented route, and the `marketplace add` → `install` path above is superseded. The install wording lives in [.agents/install-block.md](../install-block.md).

The official listing points at this repo's git URL and reads `.claude-plugin/plugin.json` directly, so it does not depend on `.claude-plugin/marketplace.json`. That file is retained only as a fallback for installing the repo directly (an unreleased commit, or a fork).

Verified 2026-08-05, on Claude Code 2.1.222, against the live listing:

- `claude plugins install mattpocock-skills` resolves with no marketplace added first, and reports `mattpocock-skills@claude-plugins-official`.
- `claude plugin details mattpocock-skills` then reports version 1.2.0 and loads the promoted skills.
- The listing's `source` is `{"source": "url", "url": "https://github.com/mattpocock/skills.git", "sha": …}`: the **sha is pinned**, so a release reaches installed users when that pin moves, not the moment we tag. At the time of writing the pin sits two commits behind `main`, which is why it lists 22 skills rather than the 24 in `plugin.json`.
- The in-session `/plugin install mattpocock-skills` was **not** exercised: `/plugin` is unavailable in headless (`claude -p`) sessions. It runs the same resolver as the CLI, and the documented example form is `/plugin install <name>@claude-plugins-official`.

## Update, 2026-08-29

The second invariant above no longer holds. This repo has no `package.json`
and no release pipeline (see [0003](./0003-no-release-pipeline.md)), so there
is no second version to track and nothing reconciles the one that remains.
`.claude-plugin/plugin.json` now carries the only version in the repo.

The first invariant, one `plugin.json` entry per promoted skill, still stands
and is enforced by `CLAUDE.md`.

The 2026-08-05 update above does not carry over, and it is the most misleading
thing in this file. `mattpocock-skills` was accepted into Claude Code's
official marketplace; this repository is a different plugin, under a different
name, that has been submitted nowhere. `claude plugins install
mattpocock-skills` installs upstream's set rather than this one. Nothing
supersedes the `marketplace add` then `install` path recorded above: here that
path is the only route there is, which makes `.claude-plugin/marketplace.json`
the documented install route rather than the fallback the same section calls
it. What resolves for this repository is written in
[.agents/install-block.md](../install-block.md) and copied into `README.md`.

The verification listed under that date is upstream's, run against upstream's
live listing on Claude Code 2.1.222, and it is left standing as their evidence.
It was never a claim about this repository and is not restated as one.

One smaller drift in the inherited text above. "The constraint" names a
`personal/` bucket three times, in its opening bucket list, in the
escape-hatch bullet, and in the blast radius of the restructure option. This
repository has no such bucket and never received one in the snapshot: the
promoted buckets are `engineering/` and `productivity/`, and the non-promoted
ones are `misc/`, `in-progress/` and `deprecated/`. None of the three mentions
changes the argument they support, which is that a single path string cannot
express a curated subset of a bucketed repository, and that argument still
holds here with one bucket fewer.

The decision itself stands unchanged: ship the Claude Code plugin, keep
skills.sh as the universal installer, defer a native Codex plugin.
