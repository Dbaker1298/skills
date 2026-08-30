## What it does

`wayfinder` takes an effort too big for one agent session: an idea whose **destination** you can name but whose route you cannot yet see, and charts it as a shared **map** of **decision tickets** on your issue tracker, then resolves them one at a time until the way is clear.

It plans, it does not do. Every ticket holds a question whose resolution is a decision, not a slice of a build to execute, and the map is finished when nothing is left to decide before someone goes and builds the thing. That one rule is what separates a wayfinder ticket from an ordinary implementation ticket, and it is the rule most easily broken, because an agent mid-map has everything it needs to start building. When the map clears, wayfinder hands off; it does not carry on into code.

## When to reach for it

You invoke this by typing `/wayfinder`; the agent won't reach for it on its own.

It is the heaviest, densest flow in the set, so the trigger is narrow: the effort has to be genuinely larger than one agent session can hold, and the route to the destination has to be foggy. The split is a clean one: `/grill-with-docs` for single-session planning, `/wayfinder` for multi-session planning.

| What you have in front of you | What to run |
| --- | --- |
| A well-scoped feature you can settle in one sitting | [grill-me](../productivity/grill-me.md), or [grill-with-docs](./grill-with-docs.md) when there is a codebase |
| A greenfield project, or a build spanning many sessions, with the route still unclear | `/wayfinder` |
| A thread where the deciding is already done | [to-spec](./to-spec.md): skip straight past the map |
| A cleared wayfinder map | [to-spec](./to-spec.md), then [to-tickets](./to-tickets.md) and [implement](./implement.md) |
| An existing session that has already grown too big | say "hand off to `/wayfinder`" ([handoff](../productivity/handoff.md) bridges into a map as well as out of one) |

Greenfield is not a requirement. Wayfinder works on legacy and half-built codebases, and is arguably sharper there, because a lot of the fog is "what is already true here" rather than "what should we do".

## Prerequisites

The map and its tickets live on the repo's issue tracker, so wayfinder needs the tracker wiring that [setup-david-baker-skills](./setup-david-baker-skills.md) lays down. That step writes a "Wayfinding operations" section describing how the map, its child tickets, blocking edges, and frontier queries are expressed for GitHub, GitLab, or local markdown. Wayfinder resolves that doc through the pointer in your `CLAUDE.md` / `AGENTS.md` rather than a fixed path; with no tracker configured at all it falls back to local markdown files.

The tracker is not decoration. Blocking is what renders the frontier visually in the tracker's own UI, and a tracker without native dependency links (a self-hosted Gitea, say) degrades wayfinder to inferring blockers from the map text, which works but needs closer supervision.

## The map, the fog, and the frontier

The **map** is a single issue labelled `wayfinder:map`; its tickets are its child issues. It is an **index, not a store**: a decision lives in exactly one place, its ticket, and the map only gists it and links. A session loads the map at low resolution and zooms into individual tickets on demand, which is what lets a map keep growing without every session paying for its whole history.

Four things live on it:

- **Destination**: what reaching the end of this map looks like. Naming it is the first act of charting, before any ticket exists, because the destination fixes the scope every ticket is measured against.
- **Decisions so far**: one line per closed ticket, each linking to where the detail actually lives.
- **Not yet specified**: the **fog of war**. Decisions you can tell are coming but cannot yet phrase sharply. The test for fog versus ticket is whether you can state the question precisely *now*, not whether you can answer it. Resolving a ticket clears the fog ahead of it and graduates whatever is now specifiable into fresh tickets.
- **Out of scope**: work ruled beyond the destination. Fog only ever gathers *toward* the destination, so out-of-scope work is closed and never graduates.

The **frontier** is the open, unblocked, unclaimed tickets (the edge of the known). A session claims a ticket by assigning it to itself before doing any work, so the assignee *is* the claim and concurrent sessions skip it. Tickets are referred to by name throughout, never by a bare `#42`; a wall of issue numbers is illegible in narration.

## The four decision-ticket types

Every ticket carries a `wayfinder:<type>` label, and is either **HITL** (worked with a human who speaks for themselves) or **AFK**, driven by the agent alone. A HITL ticket only resolves through the live exchange; an agent that answers its own grilling questions has broken it.

| Type | Mode | Reach for it when | Resolved by |
| --- | --- | --- | --- |
| `grilling` | HITL | The default. The question can be settled by talking it through. | [grilling](../productivity/grilling.md) plus [domain-modeling](./domain-modeling.md), in a fresh session |
| `prototype` | HITL | "How should this look" or "how should this behave": a question talking cannot settle. | [prototype](./prototype.md), with the built artifact linked from the ticket as an asset |
| `research` | AFK | A fact outside the working directory is blocking a decision. | A [research](./research.md) subagent, fired at charting time and burned down in parallel on a `research/<name>` branch |
| `task` | Either | Nothing to decide, but manual work blocks a decision, such as provisioning access, signing up for a service, or moving data so its shape can be seen. | The agent alone where it can, otherwise a precise checklist for the human |

`task` is the only type that *does* rather than decides, and it earns its place by unblocking a decision, never by delivering a piece of the destination. It is also the type most easily mis-read: an agent takes it for an implementation step and starts writing product code inside the map.

Research is the only exception to *one ticket per session*.

## Common questions

**How is this different from `/grill-with-docs`? Which should I start with?**
Session count, not project size. `/grill-with-docs` is single-session planning; wayfinder is multi-session planning. If you can hold the whole thing in one conversation, grilling is the cheaper and better tool, and wayfinder is genuinely slower and denser for that case. The short version: wayfinder only makes sense if the work does not fit into a single session. That line is easy to state and hard to apply, because nothing in either skill's description tells you where your own task sits on it. You have to judge the session count yourself, before you start.

**When it asks for the "destination", does it mean the end of this session or the end of everything?**
The whole map. That means the destination of the entire map, not just the initial session. The question reads ambiguously because wayfinder is by definition a multi-session tool, so a session-scoped answer never makes sense. Typical destinations are a spec to hand off, a decision to lock before planning starts, a proof of concept, or a change made in place like a data migration.

**The map is cleared. Didn't wayfinder already write the spec and make the tickets? Why do I still need `/to-spec` and `/to-tickets`?**
No. Wayfinder's tickets are decision tickets, and by the time the map closes they are all closed too. What is left is a map full of linked decisions, which is not a build plan. [to-spec](./to-spec.md) collapses those linked decisions into one spec (`/to-spec #<map_issue>`) and [to-tickets](./to-tickets.md) slices that into tracer-bullet implementation tickets. Looping the map straight into [implement](./implement.md) skips the collapse and throws the linked detail away. Go straight to implementation only when the effort turned out genuinely small, and understand what you are trading away: the two extra steps buy an explicit spec artifact that a reviewer or a colleague can read. That matters more the less solo you are, and not at all if the answer only ever has to satisfy you.

**My agent started writing production code in the middle of a wayfinder session.**
There is a real hole here, and it is structural. The "plan, don't do" default is explicit in the skill, and so is its escape hatch: an effort can override it in the map's **Notes**, carrying execution into the map itself. But the Notes are written by the agent, so the constraint and its exemption live in the same file the constrained party owns and edits. An agent that writes "this map carries execution" into its own Notes will read that back in every later session as its own licence, and nothing in the skill stops it or asks you to confirm. Three defences:

- Read the Notes on any map you did not chart yourself, before you resolve a ticket on it.
- Keep implementation in its own sessions, separate from any wayfinder session.
- Treat any `wayfinder:task` that looks like a slice of the build as mis-typed. A task exists to unblock a decision, not to deliver the destination.

**I charted 27 tickets, and by the time I got to the thirteenth, the rest no longer made sense.**
Expect this on a big map. The default instinct is to plan comprehensively, and a map whose later tickets rest on assumptions the earlier ones go on to invalidate is exactly the waterfall trap the skill is meant to avoid. Two things push back on it. Scope the map to a bounded destination rather than to the whole product: one defined piece of work holds together where a sprawling "implement V1" cannot, and planning something very big was never the goal, shipping small increments is. And prototype aggressively, because the only reason the route stays current is that uncertainty gets flushed out by cheap concrete artifacts before later tickets depend on it. Wayfinder is "prototypemaxxing", not "planmaxxing".

**Can I work several tickets in parallel?**
The frontier is built to show you what is takeable, and blocking edges are there so parallel work is safe on paper. In practice one-at-a-time is the safer default, and the reason is that sessions share no context. Two grilling tickets running side by side will ask you in one session a question you just answered in the other, and neither will know. Prototype tickets have a sharper version of the problem: the type is human-in-the-loop, existing to give you something concrete to react to, so an agent that builds three variations, picks one itself and closes the ticket has skipped the only step that mattered. The selection is yours, and the skill does not say so loudly enough to stop it. If you do run in parallel, read the dependency graph yourself first.

**Do I have to use GitHub Issues?**
No. Any issue tracker works. GitHub is the best-supported path because the skill leans on native sub-issues and blocking relationships, which is what renders the frontier in the tracker's own UI so you can see what is takeable without opening the map. Two honest caveats. A tracker with no native blocking falls back to a body-text convention, so the dependency graph is inferred from prose and needs correcting by hand. And local Markdown puts the artifacts in your repo, where planning material that was meant to be transient quietly persists. If your tracker is public, weigh that against the opposite cost: a public tracker fills up with agent-generated planning tickets that nobody outside the effort wants to read.

**The grilling is exhausting. Every question is three paragraphs long.**
This is an unresolved problem with the skill, and it has two halves. Verbosity costs you attention, which is fatal to a tool whose entire output is your decisions. And length crowds out *why* a question is being asked, so as the map grows you lose the chain from one decision to the next, which is the thing the map exists to hold. It reads as a property of how current models write rather than of the skill, since nothing in the skill asks for three paragraphs. Two mitigations worth trying: run a lower reasoning effort, and put a plain-language instruction about question length in your global `CLAUDE.md`. Expect to spend real thought here regardless, since the amount of thinking wayfinder demands from you is not a defect but most of what it is for.

**A decision I already closed turned out to be wrong. Do I edit the old ticket or make a new one?**
There is no official guidance, and the agent's instinct is unhelpful: it tends to design around the bad decision rather than challenge it, so you have to steer manually. What does work is telling wayfinder plainly what changed; it updates the map, revises the affected tickets, and comments on already-closed ones. Scope changes mid-map are recoverable. A map you *designed* to change is a scoping smell.

**Where did `decision-mapping` go?**
It is this skill, renamed to `wayfinder` and invoked as `/wayfinder`. "Decision map" was jargon and was also inaccurate, since only one of the four ticket types is really a decision by itself. The reframe gave the skill one coherent vocabulary (destination, fog of war, frontier, the map) instead of an invented term layered on top. The unit kept the "decision" word, though: a **decision ticket** is what a wayfinder ticket is called, precisely to stop people reading it as an implementation ticket.

## It's working if

- The destination is written down and agreed before a single ticket exists.
- Every open ticket reads as a question. Any ticket that reads "build the X" is either mis-typed or belongs downstream of the map.
- You can look at your tracker and see which tickets are takeable without opening the map, since that is the frontier rendering itself through native blocking.
- A session resolves one ticket, posts the answer as a resolution comment, closes it, and leaves one line on the map's *Decisions so far*. Then it stops.
- **Not yet specified** shrinks over time. A patch of fog that graduates into a ticket disappears from that section rather than living in both places.
- When the opening breadth-first grill turns up no fog at all, the skill stops and tells you the effort is small enough to skip the map.
- The session that finishes the map hands you toward a spec, not a pull request.

## Where it fits

`wayfinder` is a **situational on-ramp**, not the default front door. The grill-led idea → ship chain is the default route; wayfinder is what you climb onto when the idea is too big to hold in one session, and it merges back onto that chain at [to-spec](./to-spec.md), because a cleared map hands off rather than builds.

Underneath, it is mostly other skills wearing wayfinder's scheduling: [grilling](../productivity/grilling.md) and [domain-modeling](./domain-modeling.md) resolve the default ticket type, [prototype](./prototype.md) resolves the tickets that talking cannot, and [research](./research.md) runs as a subagent so its reading never lands in your session. [handoff](../productivity/handoff.md) is the bridge in and out: into a map from a conversation that outgrew itself, out of one when a side quest appears mid-session.
