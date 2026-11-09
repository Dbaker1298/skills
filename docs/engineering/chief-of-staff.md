## What it does

`chief-of-staff` turns one long-running session into the coordinator of a goal too big for a single task. The agent becomes the goal's directly responsible individual: it dispatches every piece of work to a background subagent, keeps talking to you while they run, and remembers what it learns in a **wiki** that outlives the session.

It does no work in its own context window. That is what lets the session run for days: the coordinator holds the goal, the decisions, and pointers to where the details live, while the subagents carry the exploration and the code. It also works on two tracks at once. Every task gets the tactical question (how do I finish this?) and the strategic one (what change to the environment makes the *next* task go better?).

## When to reach for it

You invoke this by typing `/chief-of-staff`, and the agent won't reach for it on its own.

| Your situation | Reach for |
| --- | --- |
| A goal that will take many tasks and many days, and that you want one session to own | `/chief-of-staff` |
| One spec, already split into tickets, to land in one run | [implement-spec](./implement-spec.md) |
| A big piece of work whose route is still unclear | [wayfinder](./wayfinder.md) to chart it first |
| One ticket | [implement](./implement.md) |

## Prerequisites

- **A place for the wiki.** The skill looks for a wiki the user or other agents already keep and writes into it. If there is none, it agrees a location with you before the first write.
- **A harness that runs subagents in the background.** Without one the coordinator does the work itself and loses the point.
- **The sibling skills it borrows procedures from**: [retro](./retro.md), [to-spec](./to-spec.md), [to-tickets](./to-tickets.md) and [implement-spec](./implement-spec.md), installed beside it. The plugin ships all of them together.

## The wiki is history, not a snapshot

The wiki is the coordinator's long-term memory: an `index.md` plus one page per decision, recurring problem, subsystem or preference, kept alive by three operations:

- **Ingest**: something durable was learned, so update every page it touches.
- **Query**: read the index before a decision.
- **Lint**: hunt periodically for contradictions, orphans and stale claims.

Every claim is dated, and every claim about code cites the commit it was true at. The wiki never says how the code *is*, because it cannot keep up with the code; it says what was true and when. When something changes, a new dated claim supersedes the old one rather than overwriting it.

## The pit of success

The strategic track is the skill's leading idea. Before any task, the coordinator asks how the environment could make agents succeed by default:

- **Constrained interfaces and lint rules** that make the wrong thing hard to write.
- **Coding standards** the reviewer can enforce.
- **Data sources** the agents need: dev server logs, a test database, a browser.
- **A "no workarounds" rule**: a deviation from convention is fixed before feature work continues, not routed around.

## Common questions

**How does a user-invoked skill run `retro` and `implement-spec`, which are user-invoked too?**

It doesn't invoke them. It reads their `SKILL.md` files from the sibling folders and follows them as procedures. This is the one place in the set that reaches across folders like this, because no harness lets one user-invoked skill fire another. One change applies: where `retro` would hand its candidates to you, the coordinator decides which to pursue and pursues them.

**Does it set up recurring jobs on its own?**

It suggests them, where the harness supports schedules: a periodic wiki lint, for example. Whether one runs is still your call.

**What survives when the session compacts or ends?**

Whatever reached the wiki. Anything that lived only in the coordinator's context window is gone, which is why ingest happens at the moment something is learned rather than at the end.

## It's working if

- The coordinator's own turns are short: dispatches, decisions and replies to you, not file dumps.
- The wiki grows dated, linked pages, and a fresh session can pick up the goal from `index.md`.
- Each task leaves the repo slightly easier for the next one: a new check, a pointer, a standard, a log the agents can now read.

## Where it fits

`chief-of-staff` is a long-running orchestrator that sits above the main flow and drives it, not a step in it.

- [implement-spec](./implement-spec.md) is how it lands a large chunk of work, after [to-spec](./to-spec.md) and [to-tickets](./to-tickets.md).
- [retro](./retro.md) is how it learns from its subagents: it runs one on about one in five of their sessions, the troubled ones first.
