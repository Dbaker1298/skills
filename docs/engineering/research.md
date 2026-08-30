## What it does

`research` answers a question by reading the sources that own the answer, then leaves a cited Markdown file in the repo. It works only from **primary sources**: official docs, source code, specs, first-party APIs. It follows every claim back to the source that owns it, so it will not repeat a blog post's account of an API when the API's own docs are reachable.

It does not answer you in the conversation. The output is a file, written where the repo already keeps such notes, with a link on each claim. That is the point: a document you can react to, hand to another agent, or throw away, rather than an answer that vanishes when the session ends.

## When to reach for it

Type `/research`, or the agent reaches for it automatically when a task turns into reading legwork.

Reach for it when the next step is *finding something out* from outside the working directory (how a third-party API behaves, what a spec actually says, whether a version claim holds), and you'd rather not stall your own thread doing the reading. What you need decides which skill:

| What you need | Reach for |
| --- | --- |
| An external fact a decision is waiting on | `research` |
| A decision made *with* you, by interview | [grilling](../productivity/grilling.md) |
| A durable architecture decision, written into `CONTEXT.md` and ADRs | [grill-with-docs](./grill-with-docs.md) |
| To find out whether an approach works in your codebase | [prototype](./prototype.md) |
| A plan too big to hold in one session | [wayfinder](./wayfinder.md) |

The line between `research` and `grill-with-docs` is the **shelf life of what comes back**. Research produces short-lived assets: what this library's auth mechanism does as of this week. An ADR records a decision you keep. If what you are producing is a decision rather than a fact, you are grilling, not researching.

## Delegated legwork

The defining move is that the reading runs as a **background agent**. You keep working; it goes off, follows each claim to its primary source, writes one Markdown file, and reports back. Research is legwork you delegate, not thinking you outsource: you get a document to grill, plan, or design against, and you still make the call.

The delegation is unguarded, and the background agent can spawn a further background agent of its own. This is the skill's best-documented rough edge.

Where the file lands is decided by the repo, not by the skill: it matches whatever convention already exists for notes, and if there is none it picks somewhere sensible and tells you where. It writes one file per run.

## Common questions

**It spawned a second research agent. Is that meant to happen?**

No, and the cause is visible in one line of the skill. It says to spin up a background agent and never says which kind, so the agent that gets spawned is a general-purpose one holding the same tools and reading the same instructions, and it does the obvious thing with them: spins up a background agent. The duplicate runs out of your view and finishes whenever it finishes, so the cost lands without anything to look at. A line telling an agent that is already a subagent to do the work itself patches it in your installed copy, but that is instruction rather than structure, and instructions are what produced the loop. Watch your background task list after invoking, and stop the duplicate.

The opposite failure exists as well: if your own global instructions forbid an agent from re-delegating work, the background agent will politely decline the task and the skill quietly does nothing.

**Where should the file live, and should I commit it?**

The skill puts the file where the repo already keeps notes and has no opinion beyond that, so the decision is yours, and the honest default is: keep ADRs, do not keep research files. A research file records what was true on the day it was written. Leave one in the repo after the work has moved on and it becomes cruft that poisons later reads, because an agent scanning the tree cannot tell a current finding from a stale one and will happily reason from either. If you want them durable, a notes app, a separate knowledge repo or the issue tracker all keep them out of the way of the code.

**What counts as a "high-trust" primary source, and who decides?**

The model does, and that is the weak point of the whole design. The skill names the *kinds* of source that qualify (official docs, source code, specs, first-party APIs) and stops there: no allowlist, no domain gate, no verification pass. Several subagents pointed at junk give you several confident wrong answers faster than one would. The mitigation you actually have is the citation on each claim, so use it: follow two or three. If they land on a summary of the thing rather than the thing itself, the run failed at its one job and the document is worth less than nothing.

**Does a later session reuse what an earlier run found?**

No. Nothing auto-loads a past research file; it is a document sitting in the repo until a human or another skill points at it. That is the sharpest challenge to the design, because the value was supposed to be a document later sessions re-read, and a write-once file nobody reads again is an expensive search. The skill does not solve it, so you have to: feed the file into the next step deliberately. Attach it to a spec, quote it into a grilling session, point a ticket at it.

**Why not just ask the agent to go read the docs?**

You can, and a two-line prompt saying exactly that was the practice this skill replaced. Two things the skill buys over the prompt: it runs in the background so your session keeps its context clean, and the primary-source constraint and the cited-file output come out the same way every time rather than however you happened to phrase it. Against a harness's own deep-research mode, the difference is the artifact and the source discipline, not the search. If a two-line prompt gets you what you need on a small question, use the two-line prompt.

**When does it stop reading?**

There is no stopping criterion in the skill at all, and the gap shows up in two shapes that look opposite and are not: a run that goes far deeper than the question needed, and a run that covers the topic broadly while missing the one detail you were actually after. Both are the same missing thing, which is a definition of done. Supply it in the question. One API, one behaviour, one version claim comes back far better than "research X", because a narrow question carries its own stopping criterion.

**`/wayfinder` created research tickets. Do I resolve those myself?**

No, it fires them for you. Charting spawns a subagent per `research` ticket and burns them down in parallel, capturing each one's findings on a throwaway `research/<name>` branch with a context pointer from the ticket. They are the one exception to wayfinder's never-resolve-more-than-one-ticket-per-session rule, and the reason is that nothing waits on you while they run. The snag to know about is those branches: the ticket holds a pointer into one, so deleting the branch once the work looks finished breaks the pointer and the decision loses its evidence.

## It's working if

- Your own session keeps going. If you are sitting watching it read, the delegation didn't happen.
- Exactly one new background task appears. A second one with a near-identical name is the nesting bug.
- One new Markdown file shows up, in the folder the repo already uses for notes, and the agent tells you the path.
- Every claim in it carries a link, and following two at random lands you on an official doc, a spec, or the actual source file, not on someone's write-up of it.
- You can make the decision you were stuck on from the file alone, without going back to the sources yourself.

## Where it fits

A reach-for-it-anytime standalone that feeds the thinking skills rather than sitting in the build chain. Its file is something to take *into* the flow: [grilling](../productivity/grilling.md) and [grill-with-docs](./grill-with-docs.md) ask sharper questions when the facts are already on the table, and [to-spec](./to-spec.md) can synthesise against it. [wayfinder](./wayfinder.md) is the one skill that invokes it directly, resolving each research ticket on its map with a `/research` subagent.
