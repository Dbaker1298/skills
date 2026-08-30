## What it does

`to-tickets` takes a plan, a spec, or the conversation you are in, and breaks it into a set of **tickets** on your issue tracker. Each ticket declares its **blocking edges**: the other tickets that have to finish before it can start.

Every ticket is a **tracer bullet**: a narrow but complete path through every layer of the change (schema, API, UI, tests) that can be demoed on its own the moment it lands. That is the constraint that makes it behave differently from the obvious way to split work, which is to cut one layer at a time and integrate at the end. It also sizes each ticket to fit in a single fresh context window, because the thing that will pick the ticket up is a session that has never seen your spec.

## When to reach for it

You invoke this by typing `/to-tickets`. The agent won't reach for it on its own.

| Where you are | What to run |
| --- | --- |
| You have a spec issue and the build spans several sessions | `/to-tickets`, or `/to-tickets #<spec_issue>` |
| The plan is only in the conversation, never written up | `/to-tickets` reads the thread directly, no spec needed |
| The whole change fits in one context window | [implement](./implement.md), skip the tickets |
| Nothing is decided yet | [grill-with-docs](./grill-with-docs.md), then [to-spec](./to-spec.md) |
| A [wayfinder](./wayfinder.md) map has cleared | [to-spec](./to-spec.md) first, to collapse the map, then `/to-tickets` |

Tickets that `to-tickets` produced are agent-ready by construction. Don't run [triage](./triage.md) over them. Triage is for work that arrived from someone else.

## Prerequisites

`to-tickets` publishes into a tracker, so [setup-david-baker-skills](./setup-david-baker-skills.md) must have configured one for this repo, along with the triage-label vocabulary. Either kind works: a real tracker like GitHub or Linear, or local markdown files under `.scratch/`, which is supported out of the box.

## Tracer bullets, not layers

A **horizontal** slice ships one layer of the change. Nothing works until every layer has landed, and each ticket's acceptance criteria have to reach into work that another ticket owns. A **vertical** slice (the tracer bullet) ships one thin path through all the layers at once, so it is verifiable alone and owns everything it grades.

This is the rule most worth holding to, because breaking it is expensive in a way that is invisible until late. Slice a stack by layer (corpus, producer, aggregator, selector) and each ticket delivers something nothing can exercise, so nothing is verified until the last one lands and every mistake made early is discovered at the end. The rework arrives in a heap, and it traces back to the slicing rather than to any of the implementations.

Two things happen before anything is published. `to-tickets` looks for prefactoring (the principle "make the change easy, then make the easy change") and orders that work first. Then it presents the breakdown as a numbered list and quizzes you on it: is the granularity right, are the blocking edges real, should anything merge or split. Nothing reaches the tracker until you approve, and that quiz is the place to push back.

## Blocking edges

The edges are the point of the artifact. They read two ways depending on the tracker:

| Tracker | Where the edges live | How you work them |
| --- | --- | --- |
| Local markdown | Text in one file per ticket under `.scratch/<feature>/issues/<NN>-<slug>.md`, numbered blockers-first | Top to bottom, by hand |
| A real tracker (GitHub, Linear) | Native blocking links, or sub-issues where the tracker has them | Any ticket whose blockers are done is on the **frontier** and can be grabbed |

The edges live in the ticket either way. The medium only decides whether anything can act on them in parallel. `to-tickets` produces the artifact; running it (one session at a time, or a fleet) is your job, not the skill's.

## The wide-refactor exception

One shape breaks the tracer-bullet rule. A **wide refactor** is a single mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase, so one edit breaks thousands of call sites and no vertical slice can land green.

`to-tickets` sequences that as **expand–contract** instead:

- **Expand**: add the new form beside the old, so nothing breaks.
- **Migrate**: move call sites over in batches sized by blast radius (per package, per directory), one ticket per batch, each blocked by the expand. CI stays green because the old form still exists.
- **Contract**: delete the old form once no caller remains, in a ticket blocked by every migrate batch.

Where even the batches can't stay green alone, they share an integration branch and all block a final integrate-and-verify ticket. Green is promised only there.

## Common questions

**It produced twelve tickets for a three-line change.**
Over-decomposition is the failure mode to expect from this skill: asked to break work down, a model defaults to the smallest units it can defend and loses the grouping that would have made them meaningful. The quiz step exists for exactly this: ask it to merge, and it will. The deeper answer is that the tickets have a floor: if the whole change fits in one context window, you don't need this skill at all. Go straight to [implement](./implement.md).

**The tickets came out one per layer: all the schema in one, all the API in another.**
This is the failure the vertical-slice rule is written against, and the skill still produces it sometimes. Catch it at the quiz step by asking one question per ticket: what can I demo when this is done? A ticket with no answer is a horizontal slice. Asking for a "demo path" line on every ticket makes the same check part of the artifact, so the pressure applies while the tickets are being written rather than after.

**On GitHub the tickets weren't created as sub-issues of the spec issue.**
The skill asks for the right thing and does not say how, which is enough of a gap for an agent to fall through. Its publish step says to use the platform's native blocking and sub-issue relationship where it has one, and treats a plain "Blocked by" line as the fallback for trackers that have no such thing. What it never names is the command, so the agent has to know it. `gh` does support this directly: `gh issue create --parent <n>` at creation, and `gh issue edit <parent> --add-sub-issue <n>` afterwards. Note that writing them into `docs/agents/issue-tracker.md` is not enough on its own: `to-tickets` never reads that file, it only says the how "depends on the tracker `/setup-david-baker-skills` configured". Put the two commands in your repo's `CLAUDE.md`, which an agent loads as project context whatever skill is running, and the fallback stops being the path of least resistance.

**"Blocked by" was written into the issue body instead of a real blocking link.**
Same gap, same fix. GitHub does have a native blocking relationship, whatever an agent tells you: `gh issue create --blocked-by 12,15` sets it at creation time, and because the skill publishes in dependency order with blockers first, the numbers it needs always exist by the time it gets there. The body text is the documented fallback for trackers with no native edge, not the default, so an agent reaching for it on GitHub has quietly downgraded your issue graph to prose.

**Where do the local tickets go? The v1.1 notes said a root-level `tickets.md`.**
They did, and that was a bug: a single shared file also raced when parallel agents wrote to it. Local mode now writes one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, in dependency order, matching the layout the local tracker template already described. The `NN` prefix is a real ticket ID, so `/implement 03` works instead of retyping a long title.

**It kept truncating when it tried to read my spec.**
A very large spec can outgrow what a tracker issue serves back cleanly, and there is no local copy to fall back on, so the agent then burns tool calls re-fetching chunks and never reaches the end. Don't clear or compact between `/to-spec` and `/to-tickets`. Run them in the same context window and the spec never has to be fetched back at all.

**The acceptance criteria graded nothing: some passed before any work was done.**
The template asks for criteria and says nothing about whether they can fail, so this happens. Three shapes to watch for: a criterion already true at the base commit, a criterion that can only be satisfied by work another ticket owns, and one that restates the request rather than deriving from the artifact. Vertical slicing prevents most of it (a slice that delivers behaviour which didn't exist before is red at the base commit by construction), but the check is worth doing by hand. For each criterion, name the observation that would show it false, and confirm it fails at the commit the implementer starts from.

**The tickets are published. How do I actually run them?**
The skill stops at the artifact, and there is no auto-dispatch mode. Dispatch is manual: look at the board, count the tickets with no open blockers, and open that many agent sessions. One ticket per fresh context, cleared between them. Be aware that [implement](./implement.md) does not close the ticket or check off its criteria when it finishes, on GitHub or in local Markdown, so the ticket's state is yours to update.

## It's working if

- Every ticket has an answer to "what can I demo when this is done?", and the answer is behaviour, not a layer.
- The list comes back to you numbered, with a "Blocked by" line on each, before anything is published.
- The ticket at the top has no blockers and can be started immediately.
- Nothing in a ticket body is a file path or a line number, except a snippet a prototype produced.
- Each ticket reads like something a fresh session could finish without you in the room.
- Prefactoring, where it found any, is at the front of the order rather than mixed into feature tickets.

## Where it fits

`to-tickets` is a step in the main build chain:

```txt
grill-with-docs → to-spec → to-tickets → implement → code-review
```

Upstream is [to-spec](./to-spec.md), which hands it a settled spec to slice against; keep both in one unbroken context window. Downstream is [implement](./implement.md), which builds one ticket per fresh session, driving [tdd](./tdd.md) for the tests and closing with [code-review](./code-review.md).
