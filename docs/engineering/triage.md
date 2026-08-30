## What it does

`triage` works through the issues on your project's tracker, moving each one through a small state machine of **triage roles** (a category role and a state role) and leaving behind either an agent-ready brief, a specific question for the reporter, or a closed issue with a recorded reason.

It is only for issues **you didn't create**. Raw bug reports, incoming feature requests, an external pull request that arrived unannounced: work that landed in the tracker from outside, in whatever shape the reporter left it. Tickets that [to-tickets](./to-tickets.md) produced are already agent-ready by construction, and running `triage` over them is wasted work at best. The rule is flat: `/triage` is only for incoming issues, not for issues you created yourself.

The second thing that separates it from labelling by hand: it recommends and waits. It tells you its category and state call with reasoning, plus what it found in the codebase, and applies nothing until you direct it.

## When to reach for it

You invoke this by typing `/triage` and then describing what you want in plain language. The agent won't reach for it on its own. "Show me anything that needs my attention", "let's look at #42", "move #42 to ready-for-agent".

| What you have | Where to go |
| --- | --- |
| A tracker full of raw reports from other people | `/triage` |
| A rough idea of your own, nothing written down | [grill-with-docs](./grill-with-docs.md) |
| A settled conversation to turn into a spec | [to-spec](./to-spec.md) |
| A spec to split into agent-ready tickets | [to-tickets](./to-tickets.md) |
| A confirmed bug that needs a root cause, not a label | [diagnosing-bugs](./diagnosing-bugs.md) |

## Prerequisites

`triage` reads and writes your issue tracker, so [setup-david-baker-skills](./setup-david-baker-skills.md) has to have configured that tracker and its label vocabulary first. The role names below are **canonical**; the label strings in your tracker may differ, and the mapping is what setup provides. If your tracker already uses the canonical names exactly, there is nothing to map and nothing to set up.

The tracker config also decides whether external pull requests count as a request surface, and who counts as external. That flag defaults to off and is no longer a setup question, so flip it in `docs/agents/issue-tracker.md` if you want PRs in scope.

## The state machine

Every triaged item ends up carrying exactly one category role and one state role. Two categories: `bug` (something is broken) and `enhancement` (new feature or improvement). Five states:

| State | Means |
| --- | --- |
| `needs-triage` | You need to evaluate it. Where an unlabelled issue normally lands first. |
| `needs-info` | Waiting on the reporter. Returns to `needs-triage` when they reply. |
| `ready-for-agent` | Fully specified, with an agent brief attached. An AFK agent can take it. |
| `ready-for-human` | The same brief, plus why this can't be delegated: judgment, external access, manual testing. |
| `wontfix` | Closed, with the reason recorded. |

That is the whole vocabulary, and the "exactly one state role" invariant is what keeps the queries simple. It is also where the vocabulary runs out: there is no state for work that is specified but blocked on another issue, none for work gated on a future trigger, and no terminal `implemented`. See the questions below for what to do about that.

`wontfix` splits three ways, and the difference matters because only one of them writes to the knowledge base:

| Why you're closing it | What happens |
| --- | --- |
| Already implemented | A comment pointing at where it already lives. Nothing is written to `.out-of-scope/`, because it's a built feature, not a rejected one, and filing it there would poison the dedup checks. |
| Rejected bug | Polite explanation, then close. |
| Rejected enhancement | A file in `.out-of-scope/`, linked from the closing comment, then close. |

`.out-of-scope/` is one markdown file per rejected **concept**, not per issue, written as a short design document rather than a database row: what was rejected, why, and every issue that has asked for it. `triage` reads the whole directory before it evaluates anything, and matches by concept rather than keyword, so "night theme" matches `dark-mode.md`. When it hits a match it surfaces the old decision and asks whether you still feel the same way, instead of re-litigating the request from scratch.

## Verify before you brief

Before any grilling, `triage` checks that the claim actually holds. For a bug, it reproduces it from the reporter's steps. For a PR, it checks the branch out and runs the relevant tests. Then it reports which of three things happened: confirmed, with the code path; failed to reproduce; or not enough detail to try, which is itself the strongest `needs-info` signal there is.

It runs two more checks against the codebase in the same pass: **redundancy** (is this already implemented, searched by domain concept rather than by the reporter's wording?) and **prior rejection** (does `.out-of-scope/` already say no?). Both are cheap, and both produce a `wontfix` when they hit.

All of it exists to make one artifact good: the **agent brief**, the structured comment posted when an issue moves to `ready-for-agent`. Once it's posted, the brief is the contract and the original report is only context. Briefs are written to be **durable** rather than precise, because an issue can sit in `ready-for-agent` for weeks while the code moves underneath it. So they name types, signatures and behavioural contracts, and never file paths or line numbers. A confirmed reproduction makes a far stronger brief than a guess does.

## A PR is an issue with attached code

Where the tracker treats external pull requests as a request surface, they run through the same machine, with the same categories, same states, same transitions. The states just read against the diff: `ready-for-agent` means a brief is attached and an agent should take the next step on the code, `ready-for-human` means it's ready for a person to merge. A brief on a PR describes what's left to do to the existing diff, not how to build the thing from nothing.

Discovery surfaces only *external* PRs, because a collaborator's in-flight branch is not triage work. That filter is discovery-only, and naming a PR explicitly gets it triaged whoever wrote it. One rough edge to know about: the external-PR listing command asks `gh pr list` for an `authorAssociation` field, and `gh` does not expose that field on pull requests, so the command fails outright rather than returning a short list. It reaches your repo from the GitHub tracker template that setup copies in, so correcting it in your own `docs/agents/issue-tracker.md` fixes this repo and the next one still arrives with it. Until then, filter on `author` and decide who counts as external yourself.

## Common questions

**I ran `/to-spec` and `/to-tickets`, and now those tickets are sitting there untriaged. Do I run `/triage` over them?**
No. They are already agent-ready, because `to-tickets` applies the `ready-for-agent` label as it publishes, precisely so an AFK runner picks them up without another pass. `triage` is the on-ramp for work that arrives from outside; the spec flow is the lane for work you originate. They meet at `ready-for-agent`, not before.

**Is `triage` still relevant now that there's a `to-spec` → `to-tickets` → `implement` flow?**
Only if you have inbound work. `triage` predates that spine and does a different job: it is the lane for reports other people filed. If everything in your tracker came out of your own planning, you will rarely open it. If you maintain anything public, or your team files bugs at you, it is the front door. The clearest case is a public repository taking issues from people outside the team.

**The agent tried to apply `ready-for-agent` and `gh` said the label doesn't exist.**
Setup writes the vocabulary down; it never creates it. `setup-david-baker-skills` fills in `docs/agents/triage-labels.md` with the five canonical roles and their label strings, and nothing in that run touches your tracker, so the first triage that tries to apply a role fails on a label that only ever existed in a Markdown table. Create them yourself, once, with `gh label create` or your tracker's UI: the five states, plus `bug` and `enhancement` for the category role. Then it stops. If you renamed any of them during setup, create the names in the right-hand column of that table rather than the canonical ones.

**Five states aren't enough: what about blocked, or deferred, or implemented?**
They are five states of *triage*, and they stop where triage stops, which leaves three gaps worth naming before you hit them. An issue that is fully specified but waiting on another issue to close is `ready-for-agent` in the literal sense and misleading in practice, because an AFK runner takes it and walks into the wall. Trigger-gated work, intended but not actionable yet, has nowhere honest to sit: `ready-for-agent` is a lie and `needs-triage` is one too. And there is no terminal "implemented, awaiting verification", so a runner polling on labels can re-queue a ticket that is already done.

The fix that does not fight the skill is a repo-local label carried alongside the canonical role: keep the state slot filled with something true, and let the extra label carry what triage has no word for. The cost is that the skill does not know about it, so nothing enforces the pairing and your own queries have to.

**How is this different from `/diagnosing-bugs`?**
The verification step here is deliberately shallow (enough to answer "is this real, and roughly where does it live"), not to find a root cause. When a bug won't reproduce from the reporter's steps in a few minutes, the honest move is `needs-info`, or [diagnosing-bugs](./diagnosing-bugs.md) if you want to chase it now. Neither skill's text mentions the other, so nothing hands off automatically: the call is yours to make at the point the reproduction stalls.

**Can I point it at my whole backlog and let it run?**
You can ask, but watch what it reads. The "show what needs attention" pass is a cheap listing meant for *selection*, where you pick one, and then it gathers full context on the one you picked. Run it across twenty issues at once and an agent can quietly fall back to that listing as its evidence base, and the listing was never built to be one: it is counts and a one-line summary per item. Only the per-issue pass reads the body, the comments, the labels and the dates. So an issue whose comments already say "fixed, recommend closing" reaches you as a fresh agent brief, because nothing read the comment. If you want a bulk pass, say explicitly that comments must be read per issue.

**Does it work with Linear, or anything other than GitHub Issues?**
Yes. The tracker is configuration rather than a hard-coded assumption: `setup-david-baker-skills` writes `docs/agents/issue-tracker.md`, and every skill that touches issues reads its commands out of that one file. Anything you can drive from a CLI fits, and so does a plain Markdown convention under `.scratch/`. Splitting tools across the two is fine as long as you say so there, because "issue tracker" and "PR" are separate lines in that file and can name different systems.

## It's working if

- Every item it touches ends with exactly one category role and one state role, never zero, never two states in conflict.
- It gives you a recommendation with reasoning and stops, rather than relabelling and moving on.
- The bug got reproduced, or the PR got checked out and run, before anything reached `ready-for-agent`.
- The briefs it writes name types and behaviours, and contain no file paths and no line numbers.
- A request that was rejected six months ago comes back, and it says so and quotes the old reason instead of triaging it fresh.
- Every comment it posts opens with `> *This was generated by AI during triage.*`

## Where it fits

`triage` is an **on-ramp**, not a step in the main chain. The main flow runs from an idea you had (grill, spec, tickets, implement, review), and `triage` is the parallel lane for work that arrived instead. It merges at the same place: an issue labelled `ready-for-agent` with a brief on it, which [implement](./implement.md) picks up exactly as it would a ticket from [to-tickets](./to-tickets.md). When a request needs sharpening before it can be briefed, `triage` runs [grilling](../productivity/grilling.md) and [domain-modeling](./domain-modeling.md) together, a round of questions at a time, so decisions land in `CONTEXT.md` and the ADRs as they're made.
