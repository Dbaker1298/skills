## What it does

`implement-spec` takes a spec and its tickets and lands the whole thing in one run. The orchestrating agent hands each ticket to an implementer subagent working in its own git worktree, merges each finished branch into a single **integration branch**, runs [code-review](./code-review.md) over the result, and resolves the tickets.

It reads the tickets as a **task graph**, not a list. Blocking edges decide what can start, so at any moment there is a **frontier** of tickets whose blockers have all landed, and every ticket on the frontier runs at once. That is the difference from working the tickets one by one: the graph's shape, not its order on the tracker, sets the pace.

## When to reach for it

You invoke this by typing `/implement-spec`, and the agent won't reach for it on its own.

| Your situation | Reach for |
| --- | --- |
| A spec, split into tickets with blocking edges, that you want landed in one run | `/implement-spec` |
| One ticket at a time, in your own context window, clearing between tickets | [implement](./implement.md) |
| A spec that isn't split into tickets yet | [to-tickets](./to-tickets.md) first |
| A small piece of work with no real graph to it | [implement](./implement.md) directly |

## Prerequisites

- **An issue tracker.** The skill reads the tickets from, and resolves them on, the tracker [setup-david-baker-skills](./setup-david-baker-skills.md) configured. If none has been configured, it stops and tells you to run that first rather than guessing.
- **Tickets with blocking edges**, as [to-tickets](./to-tickets.md) writes them. Without edges the graph is flat and every ticket starts at once.
- **A harness that runs subagents in the background and gives each one a git worktree.** The concurrency is the point; a harness that runs subagents one at a time gets a slower `implement`.

## The integration branch

Everything lands on one branch. Each implementer:

1. confirms its worktree is based on the integration branch before it starts,
2. builds its ticket with [tdd](./tdd.md), red-green one slice at a time,
3. merges the integration branch tip into its own branch before reporting done, so landing it is a fast-forward.

Whether a pull request exists at all is the tracker's call. If your tracker closes work through PRs, or you ask for one, a draft PR opens after the first merge and is marked ready at the end. Otherwise the run stops on the integration branch with every ticket resolved the way your tracker closes work, which works fully offline against a local markdown tracker.

Implementers talk to the orchestrator through **context pointers** (the spec, the ticket, shared exploration notes, earlier commits) rather than pasted summaries, which keeps each subagent's prompt small and the orchestrator's window free for the graph.

## Common questions

**How is this different from running `/implement` on each ticket myself?**

With `implement` you are the dispatcher: one session per ticket, clearing in between, and keeping track yourself of which tickets are unblocked. `implement-spec` hands that job to one orchestrating session. The price is that you no longer read each ticket's work as it lands; you review the integration branch at the end. To start a run, clear the context and type `/implement-spec` with a pointer to the spec (an issue number or a file path). For a small change with no real graph, skip it and use `implement` directly.

**Does it need GitHub?**

No. The goal is the integration branch. A PR opens only when the configured tracker closes work through PRs or you ask for one, so on a local markdown tracker the run ends with every ticket resolved and the work merged on the branch.

**The review and fix loop will not stop.**

`code-review` compares the code against the whole spec, so it only makes sense once every ticket has landed, and the skill runs it once at the end and sends every finding to a single fix subagent. It does not say when to stop after that fix. If you see a second broad review start, tell it to run focused checks for the fixed findings and stop. Expect that first review to find real problems: the run's output is a draft that the review finishes, not something to ship on its own.

**Two implementers running in parallel collided on the same file, or picked different names for the same thing.**

Worktrees don't remove collisions; they postpone them to merge time. A blocking edge written from ticket text is a guess about which files each ticket will touch, and two tickets on different parts of the codebase can still share a message catalogue, a config registry, or a type. Each implementer sees only its own ticket and the shared notes, never the other's work in progress. When two frontier tickets touch one shared surface, either add a blocking edge between them so they run one after the other, or have the exploration notes fix the exact names each ticket adds.

**Blocked tickets never start, even after their blocker has merged.**

On GitHub, the tracker's blocked-by count only drops when a blocker *closes*, and tickets typically close when the PR merges, which is the end of the run. The tracker is the right source for the starting graph but a stale one mid-run. Tell the orchestrator to track which tickets have merged into the integration branch itself and compute the frontier from that.

**A ticket's key test was skipped inside its worktree, and it reported green.**

A worktree holds only what git tracks. Tests that read gitignored fixtures, local databases, or credentials can skip themselves there silently. For a ticket whose verification depends on untracked material, tell the orchestrator to run it in the main checkout instead.

## It's working if

- Several implementers are running at once whenever the graph allows, not one after another.
- A ticket starts as soon as its last blocker lands on the integration branch, not when the whole run ends.
- Every ticket's trace shows `tdd` running, with a failing test before the code.
- Merges into the integration branch are fast-forwards, not conflict resolutions.
- The run ends on one branch with every ticket resolved, and a PR only if your tracker wanted one.

## Where it fits

`implement-spec` is the build step of the main chain, as the parallel alternative to running [implement](./implement.md) once per ticket:

```txt
grill-with-docs → to-spec → to-tickets → implement-spec → retro
```

Its neighbours are [to-tickets](./to-tickets.md), which declares the blocking edges it reads as a task graph, and [code-review](./code-review.md), which it runs over the integration branch before closing out. [retro](./retro.md) follows a run worth learning from.
