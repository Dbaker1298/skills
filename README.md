# David Baker's Skills

Agent skills for the parts of building software that a coding agent gets wrong on its own: working out what to build, turning it into specs and tickets, driving tests, reviewing the diff, and keeping the design coherent as the codebase grows.

This repository was seeded from [mattpocock/skills](https://github.com/mattpocock/skills) and inherits its MIT licence, reproduced in [LICENSE](./LICENSE) with both copyright lines. It is not a fork: the history here is independent, and [UPSTREAM.md](./UPSTREAM.md) records the seed commit and how I review what has changed upstream since.

Each skill is a Markdown file telling an agent how to do one thing well. There is no framework and no runtime, so you can read one in a minute and change it in two.

## Installation (30-second setup)

Two ways in, two philosophies. **The [Claude Code plugin](https://code.claude.com/docs/en/plugins)** installs the whole set as a managed, read-only bundle you subscribe to rather than fork. **[skills.sh](https://skills.sh)** copies editable skill files into your project, so you can hack on them and make them your own. Pick one: installing both leaves you with every skill twice.

### 1. Get the skills

<details>
<summary><strong>Claude Code</strong></summary>

```bash
claude plugin marketplace add Dbaker1298/skills
claude plugin install david-baker-skills@dbaker1298
```

Or, from inside a session:

```
/plugin marketplace add Dbaker1298/skills
/plugin install david-baker-skills@dbaker1298
```

The marketplace has to be added first, and it is added once. Updates are not automatic: `claude plugin marketplace update dbaker1298` refreshes the source, then `claude plugin update david-baker-skills` applies it, and a restart is required before the new version loads.

</details>

<details>
<summary><strong>Codex, and other agents</strong></summary>

```bash
npx skills@latest add Dbaker1298/skills
```

Pick the skills you want, and which coding agents to install them on. **The menu lists every skill in the repository, not just the promoted set, so the `in-progress/` bucket is in it too: take what you want from `engineering/` and `productivity/`, and make sure `setup-david-baker-skills` is one of them.** Run it with a terminal attached. With stdin piped, as in CI, it takes the whole `skills/` tree without asking.

A native Codex plugin is on the roadmap (see [`.agents/adr/0002-ship-as-a-claude-code-plugin.md`](./.agents/adr/0002-ship-as-a-claude-code-plugin.md)).

</details>

<details>
<summary><strong>For tinkerers</strong></summary>

Use the same installer, on any agent, including Claude Code:

```bash
npx skills@latest add Dbaker1298/skills
```

It writes the skills into your repo as ordinary files you own and can edit. Nothing updates behind your back; pull the latest changes for a skill when you want them with `npx skills@latest update <name>`.

</details>

### 2. Run `/setup-david-baker-skills`

In your agent, run it once per repo. It will:

- Ask you which issue tracker you want to use (GitHub, Linear, or local files)
- Ask you what labels you apply to tickets when you triage them (`/triage` uses labels)
- Ask you where you want to save any docs we create

### 3. That is it.

## What the skills are for

Four problems recur when a coding agent does real work, and the set is organised around them.

**You and the agent are not aligned.** You describe a change, the agent builds something adjacent to it, and neither of you finds out until it is built. The answer is to be interrogated before anything is written: [grill-me](./skills/productivity/grill-me/SKILL.md) for any decision, [grill-with-docs](./skills/engineering/grill-with-docs/SKILL.md) when the project has a domain worth writing down as you go. The same interview runs underneath both.

**The agent and the codebase do not share a language.** Dropped into an unfamiliar project, an agent invents its own words for things, then spends tokens explaining them back to you. A `CONTEXT.md` glossary settles the vocabulary once, so the names in the code and the names in the conversation agree. [domain-modeling](./skills/engineering/domain-modeling/SKILL.md) builds and sharpens it; [grill-with-docs](./skills/engineering/grill-with-docs/SKILL.md) does it as part of the interview.

**The code does not work.** An agent with no feedback is guessing, and it guesses confidently. Types, tests, and something it can actually run are what turn that into iteration. [tdd](./skills/engineering/tdd/SKILL.md) holds a red-green-refactor loop and a position on what makes a test worth writing; [diagnosing-bugs](./skills/engineering/diagnosing-bugs/SKILL.md) is the disciplined loop for the bugs that do not fall to a guess.

**The design rots.** Agents produce code faster than anyone reviews it, so complexity accumulates faster too. [codebase-design](./skills/engineering/codebase-design/SKILL.md) is the shared vocabulary for deep modules, [to-spec](./skills/engineering/to-spec/SKILL.md) makes you name the modules a change touches before it starts, and [improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/SKILL.md) scans for places a module could be deepened and reports them back for you to choose from.

That framing, and most of the skills under it, came from upstream. I am keeping what I can vouch for and adapting the rest as I put it to use.

## Reference

These split on one axis: who can invoke them. **User-invoked** skills are reachable only when you type them (e.g. `/grill-me`); their job is to orchestrate. **Model-invoked** skills can be invoked by you _or_ reached for automatically by the agent when the task fits; they hold the reusable discipline. A user-invoked skill may invoke model-invoked skills, but never another user-invoked one.

### Engineering

Code work.

**User-invoked**

- **[grill-with-docs](./skills/engineering/grill-with-docs/SKILL.md)**: Grilling session that also builds your project's domain model, sharpening terminology and updating `CONTEXT.md` and ADRs inline.
- **[triage](./skills/engineering/triage/SKILL.md)**: Move issues through a state machine of triage roles.
- **[improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/SKILL.md)**: Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick.
- **[setup-david-baker-skills](./skills/engineering/setup-david-baker-skills/SKILL.md)**: Configure this repo for the engineering skills (issue tracker, triage labels, domain doc layout). Run once per repo before using the other engineering skills.
- **[to-spec](./skills/engineering/to-spec/SKILL.md)**: Turn the current conversation into a spec and publish it to the issue tracker. No interview, just synthesizes what you've already discussed.
- **[to-tickets](./skills/engineering/to-tickets/SKILL.md)**: Break any plan, spec, or conversation into a set of tracer-bullet tickets, each declaring its blocking edges, written as text in a local file, or as native blocking links on a real tracker.
- **[implement](./skills/engineering/implement/SKILL.md)**: Build the work described by a spec or set of tickets, driving `/tdd` at pre-agreed seams and closing out with `/code-review` before committing.
- **[wayfinder](./skills/engineering/wayfinder/SKILL.md)**: Plan a huge chunk of work, more than one agent session can hold, as a shared map of decision tickets on the issue tracker, and resolve them one at a time until the way to the destination is clear.

**Model-invoked**

- **[prototype](./skills/engineering/prototype/SKILL.md)**: Build a throwaway prototype to answer a design question, either a single shareable HTML file for state/logic questions, or several radically different UI variations toggleable from one route.
- **[diagnosing-bugs](./skills/engineering/diagnosing-bugs/SKILL.md)**: Disciplined diagnosis loop for hard bugs and performance regressions: build a feedback loop that goes red on this bug → minimise → hypothesise → instrument → fix → regression-test.
- **[research](./skills/engineering/research/SKILL.md)**: Investigate a question against high-trust primary sources and capture the findings as a cited Markdown file in the repo, run as a background agent.
- **[tdd](./skills/engineering/tdd/SKILL.md)**: Test-driven development with a red-green-refactor loop. Builds features or fixes bugs one vertical slice at a time.
- **[domain-modeling](./skills/engineering/domain-modeling/SKILL.md)**: Actively build and sharpen a project's domain model: challenge terms against the glossary, stress-test with edge-case scenarios, and update `CONTEXT.md` and ADRs inline.
- **[codebase-design](./skills/engineering/codebase-design/SKILL.md)**: Shared discipline and vocabulary for designing deep modules: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface.
- **[code-review](./skills/engineering/code-review/SKILL.md)**: Two-axis review of the diff since a fixed point: **Standards** (does it follow the repo's coding standards, plus a Fowler smell baseline?) and **Spec** (does it faithfully implement the originating issue/spec?), run as parallel sub-agents so neither pollutes the other.
- **[resolving-merge-conflicts](./skills/engineering/resolving-merge-conflicts/SKILL.md)**: Work through an in-progress git merge or rebase conflict hunk by hunk, resolving by intent traced to each side's primary source, then finish the operation (never `--abort`).
- **[wizard](./skills/engineering/wizard/SKILL.md)**: Generate an interactive bash wizard that walks a human through steps only they can perform: provisioning infrastructure, setting up credentials or CI secrets, walking an unfamiliar third-party dashboard, or running a one-off migration or cutover.
- **[git-guardrails-claude-code](./skills/engineering/git-guardrails-claude-code/SKILL.md)**: Install a Claude Code PreToolUse hook that blocks destructive git commands (`push`, `reset --hard`, `clean -f`, `branch -D`, `checkout .`) before the agent can run them.

### Productivity

Workflow tools that are not code-specific.

**User-invoked**

- **[grill-me](./skills/productivity/grill-me/SKILL.md)**: Get relentlessly interviewed about a plan or design until every branch of the design tree is resolved.
- **[handoff](./skills/productivity/handoff/SKILL.md)**: Compact the current conversation into a handoff document so another agent can continue the work.
- **[teach](./skills/productivity/teach/SKILL.md)**: Teach the user a new skill or concept over multiple sessions, using the current directory as a stateful teaching workspace.
- **[to-questionnaire](./skills/productivity/to-questionnaire/SKILL.md)**: Turn a decision you can't answer alone into a Markdown questionnaire for the one person who can, filled in async, or together over a meeting. It grills you about the send (who it's for, what you need back), not the subject.
- **[wait-what](./skills/productivity/wait-what/SKILL.md)**: Fire this the moment a message doesn't land. The agent re-pitches it with the context you're missing, in plain English, using your `CONTEXT.md` vocabulary.

**Model-invoked**

- **[grilling](./skills/productivity/grilling/SKILL.md)**: Interview the user relentlessly about a plan, decision, or idea until every branch of the design tree is resolved. The reusable interview primitive behind `grill-me`, `grill-with-docs`, `triage`, `wayfinder` and `improve-codebase-architecture`.
- **[writing-for-agents](./skills/productivity/writing-for-agents/SKILL.md)**: Writing documents for agents: skills, AGENTS.md/CLAUDE.md, and any doc an agent reaches by a pointer.
