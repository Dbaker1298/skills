## What it does

`setup-david-baker-skills` answers three questions about one repo: where issues live, what the triage labels are called, and where the domain docs sit. It records the answers as markdown files under `docs/agents/`.

Those files are the only thing that varies between repos. The skills themselves are identical everywhere; they read `docs/agents/issue-tracker.md` at run time and do what it says. That is why the set is not tied to GitHub, and why no skill file ever needs editing to point it somewhere else. Invoking it with "link the skills to a custom issue tracker" works with anything you can connect to programmatically, with zero changes to the skills.

It is a prompt-driven skill, not a deterministic script. It reads your `git remote`, your existing `CLAUDE.md`, your existing `GLOSSARY.md`, proposes what it found, and waits for you to confirm before writing anything.

## When to reach for it

You invoke this by typing `/setup-david-baker-skills`; the agent won't reach for it on its own. It is deliberately marked non-invokable, so no other skill can fire it for you.

Reach for it once per repo, before the first use of any other engineering skill. If [triage](./triage.md), [to-spec](./to-spec.md), [to-tickets](./to-tickets.md) or [wayfinder](./wayfinder.md) start guessing where your issues go, or apply labels your tracker doesn't have, they have not been set up here yet. A repo already halfway through a project is a fine place to run it; the skill reads what is already there and no earlier work is wasted.

## Prerequisites

It writes into the repo you run it in:

| It writes | Where |
| --- | --- |
| `issue-tracker.md` | `docs/agents/` |
| `domain.md` | `docs/agents/` |
| `triage-labels.md` | `docs/agents/`, only when the `triage` skill is installed |
| An `## Agent skills` block | whichever of `CLAUDE.md` / `AGENTS.md` already exists |

All of it is committed markdown. There is no user-level or global mode: the config lives in the repo, so every repo gets its own copy.

## The three decisions

It leads each section with the recommended answer, and skips whatever exploration already settled. Most runs are two confirmations and done.

| Decision | What it proposes | When it actually asks |
| --- | --- | --- |
| **Issue tracker** | the one matching your `git remote` | always: this is the one real choice |
| **Triage labels** | keep the five canonical names (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`) | only if the `triage` skill is installed |
| **Domain docs** | single-context: one `GLOSSARY.md` plus `docs/adr/` at the root | only if it spots monorepo signals, and then it offers a multi-context `GLOSSARY-MAP.md` |

The tracker options:

| Option | Where issues live | Needs |
| --- | --- | --- |
| **GitHub** | the repo's GitHub Issues | the `gh` CLI |
| **GitLab** | the repo's GitLab Issues | the `glab` CLI |
| **Local markdown** | files under `.scratch/<feature>/` in this repo | nothing: no remote at all |
| **Other** | wherever you say | one paragraph from you describing the workflow |

GitHub and GitLab need a repo the CLI can reach. If you pick one and no `git remote` points at that host, the skill asks you for the repo URL and wires it up (`git init` if needed, then `origin`), and it does not move on until `gh repo view` / `glab repo view` prints the project; if that still fails, it stops and tells you what is missing.

The first three ship as templates in the skill and work out of the box. Local markdown is a first-class option, not a fallback: a solo project with no remote is fully supported. One caveat is worth repeating: don't use local markdown if you're using GitHub. They are alternatives, not layers.

"Other" is not a stub either. It is the reason Jira, Linear, Azure DevOps and anything else can work: you describe the workflow, the skill records your prose in `docs/agents/issue-tracker.md`, and the downstream skills follow that prose rather than a hard-coded API. Anything you can drive from a CLI, an MCP server or a dashboard fits, because what the skills read is your description of it.

## Common questions

**My repo still has a `CONTEXT.md`. Will setup handle it?**
Yes. It looks for the glossary's old names, `CONTEXT.md` and `CONTEXT-MAP.md`, and offers to `git mv` them to `GLOSSARY.md` and `GLOSSARY-MAP.md`, fixing the links inside the map and the names in `docs/agents/domain.md`. Nothing moves until you confirm.

**Do I have to use GitHub?**

No. GitHub, GitLab and local markdown under `.scratch/` all ship as ready-made templates, and anything else works through the "other" path. The thing to understand is that the tracker is a setup answer, not a property of the skills: nothing downstream hard-codes GitHub, and each one reads whatever `docs/agents/issue-tracker.md` says.

**Do I need to re-run it after updating the skills?**

Worth doing, though the skill's own closing message is softer and tells you re-running is only needed to switch trackers or start over. The reason to re-run anyway is that the seed templates change between versions, so a `docs/agents/issue-tracker.md` written by an older release can go stale against the skills now reading it, and nothing detects the drift. If a downstream skill starts doing something the docs describe differently, re-running is the cheap fix.

**It wrote to `CLAUDE.md`, but I'm on Codex.**

A real gap, caused by a rule the skill states plainly: edit `CLAUDE.md` if it exists, else `AGENTS.md`, and never create one when the other is already there. That checks which file exists, not which harness is running, so a repo carrying a `CLAUDE.md` left over from Claude Code gets its `## Agent skills` block written somewhere Codex never reads.

| Your situation | What to do |
| --- | --- |
| Both files exist, or only `CLAUDE.md` does | Move the block to `AGENTS.md` by hand after the run |
| You want it to keep working | Make `AGENTS.md` canonical and leave `CLAUDE.md` as a one-line pointer at it |
| Neither file exists | The skill asks you which to create rather than deciding. Expect the question so it does not read as a stall |

**Does it create my triage labels?**

On GitHub and GitLab, yes: when the label section ran, it creates each configured label the tracker lacks (`gh label create` / `glab label create`), so the first triage run does not fail on a missing label. `docs/agents/triage-labels.md` itself is still only a *mapping*, telling `/triage` which strings in your tracker correspond to the five canonical roles. Two follow-ons:

- The label section only runs when the `triage` skill is installed, and on a local markdown or "other" tracker nothing is created. Edit the mapping later and the new strings are yours to create.
- [wayfinder](./wayfinder.md)'s `wayfinder:map` and `wayfinder:<type>` labels are not created here, and `gh issue create --label <missing>` fails outright rather than creating the label. Create them by hand before the first wayfinder run on a GitHub repo.

**Can I configure the other skills' behaviour here (grilling cadence, question format, tone)?**

No. It configures three things: tracker, labels, doc layout. It is not the home for per-user preferences, and that is deliberate rather than an omission: a skill that grows a settings surface stops being opinionated, and an opinion you can switch off is one nobody relies on. Preferences belong in your `CLAUDE.md` as plain instructions, which every agent reads whatever skill is running.

**Can I keep the config in `~/.claude` instead of committing it to every repo?**

No. There is no user-level or machine-level mode: every repo carries its own `docs/agents/`, and running the skills across many repos means running setup in each. That is deliberate to the extent that tracker and label choices are genuinely per-project, and a nuisance to the extent that yours are not.

**Isn't it strange to have a skill that configures the other skills?**

It is a fair objection: a skill that configures the other skills does mean a model writing the files that steer models. The trade is real, and the alternative is worse: without a setup step, every skill that touches issues has to carry its own copy of the tracker instructions, and they drift. The mitigation is that the output is inspectable, editable Markdown. Read every file it wrote, change what you disagree with by hand, and treat day-to-day tweaks as edits rather than another run.

## It's working if

- `docs/agents/issue-tracker.md` and `docs/agents/domain.md` exist, plus `triage-labels.md` if `triage` is installed.
- An `## Agent skills` section appears in the instruction file your harness actually reads, with a one-line summary pointing at each of those files.
- The tracker it proposed matches the remote you really use, and `gh repo view` / `glab repo view` finds the project from inside the repo.
- The label strings match labels that really exist in your tracker; on GitHub or GitLab, any that were missing exist after the run.
- Afterwards, `/to-tickets` publishes without asking you where issues live, and `/triage` applies labels rather than inventing them.
- Nothing in the skill files themselves changed. If setup edited a `SKILL.md`, something went wrong.

## Where it fits

`setup-david-baker-skills` is the **run-once setup** for the engineering flow, the precondition everything else assumes rather than a step in the chain. Its neighbours are its readers: [triage](./triage.md), which applies the label vocabulary written here; [to-spec](./to-spec.md) and [to-tickets](./to-tickets.md), which publish into the tracker named here; and [wayfinder](./wayfinder.md), which reads the "Wayfinding operations" section of the same tracker file to know how maps and child tickets are stored. The domain-doc layout it records is the one [domain-modeling](./domain-modeling.md) fills in later: it creates `GLOSSARY.md` and ADRs lazily, when a term or decision actually gets resolved, so an empty repo after setup is the expected state.
