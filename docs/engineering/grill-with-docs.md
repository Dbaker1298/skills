## What it does

`grill-with-docs` interviews you about a plan or design until you and the agent share one understanding of it, and writes the vocabulary and the hard decisions into your repo while it does. It is the same interview [grill-me](../productivity/grill-me.md) runs (a round of questions, then wait, then the next round), pointed at a codebase.

It is **stateful**. Every other grilling skill leaves the session in your head; this one leaves files on disk. A term gets resolved and it lands in `CONTEXT.md` the moment it resolves, not batched at the end. A decision passes three gates and it lands as an ADR. That is the whole difference, and it is also where the trouble comes from: the artifacts are real files in a real repo, so they can be absent when you expected them, and they can drift when more than one person is writing them.

## When to reach for it

You invoke this by typing `/grill-with-docs`; the agent will not reach for it on its own.

Reach for it at the start of a change, in a repo, when the plan is still fuzzy and the words for the thing are not settled yet. It is the single-session tool. Which grilling skill you want depends on what is in front of you:

| What you have | Reach for |
| --- | --- |
| You aren't working in a working directory at all | [grill-me](../productivity/grill-me.md) |
| A repo, and a change you can settle in one session | `grill-with-docs` |
| An effort too big to hold in one session (a greenfield build, a large feature) | [wayfinder](./wayfinder.md) |
| A repo with no domain docs at all, and no particular feature in mind | `grill-with-docs`, aimed at the repo rather than a change |
| A decision blocked on knowledge in someone else's head | [to-questionnaire](../productivity/to-questionnaire.md) |

The wayfinder split comes down to session count: `/grill-with-docs` for single-session planning, `/wayfinder` for multi-session planning.

## Prerequisites

The skill writes into your repo, so you need to be somewhere it is safe to write. Resolved terms go to a `CONTEXT.md` glossary at the root, or to the relevant context's `CONTEXT.md`, if a `CONTEXT-MAP.md` at the root marks the repo as multi-context. Decisions go to `docs/adr/`. Both are created lazily; nothing exists until the first term or decision crystallises, so there is nothing to scaffold up front.

It also needs two other skills present, because its own `SKILL.md` is one line that delegates to them: [grilling](../productivity/grilling.md) supplies the interview, [domain-modeling](./domain-modeling.md) supplies the writing. Installing `grill-with-docs` alone gets you a skill that does not work.

## The paper trail

Three things come out of a session, and they are not equal.

| What resolved | Where it lands |
| --- | --- |
| A term: the project's own word for a thing | `CONTEXT.md`, inline, the moment it resolves |
| A decision that is hard to reverse, surprising without context, and a real trade-off | An ADR under `docs/adr/` |
| Everything else you decided | The conversation, and nowhere else |

That third row is the one to read twice. `CONTEXT.md` is a glossary and is deliberately kept as one: no implementation details, no spec, no scratch notes. ADRs are gated on all three conditions at once, so most decisions do not qualify and most sessions produce none. A session that yields a sharper glossary and zero ADRs is working as designed, but it means the bulk of what you agreed exists only in the context window you agreed it in. Hand that same conversation to [to-spec](./to-spec.md) rather than clearing it.

The glossary is the point. Domain language is the thing this skill is actually building: the project's own words, agreed once, so you, the agent and your colleagues stop paying to re-derive them. It is worth saying that this may not buy you agent performance. A term and its plain-English expansion will usually get the same result from a model, and what the vocabulary really compresses is communication between the humans who share it. That reading leaves the glossary just as valuable; it moves where the value sits.

## Common questions

**Should I use this or `/wayfinder`?**
Scope decides it. Use this for anything you can settle in one session; use [wayfinder](./wayfinder.md) when the effort is too big to hold in one, and it charts the work as a map of decision tickets first. Wayfinder is slower and denser, and reaching for it on a well-scoped feature is the mistake to avoid. It does not replace this skill: it can drop into a grilling session for the parts of the map that suit one.

**It ran, but no `CONTEXT.md` and no ADRs appeared.**
Two causes. The mundane one: nothing qualified. ADRs need all three gates, and a session about a change with no new vocabulary genuinely has nothing to write. The real bug: run the skill inside another orchestration layer (a spec-driven wrapper, a multi-agent framework, a rule that invokes it as one step of someone else's pipeline) and the file-writing half can silently not happen while the interview runs as normal. Nothing announces it, because the interview is the visible part. If you are in that setup, check the working directory before you trust the session's output.

**It asked everything at once, with no recommendations, and never mentioned `CONTEXT.md`.**
That is the skill failing to load its two dependencies. Because `SKILL.md` is a one-line delegation, an agent that does not pick up [grilling](../productivity/grilling.md) and [domain-modeling](./domain-modeling.md) guesses at what grilling means, and you get an undifferentiated question dump. Partial loading is the more confusing case: `grilling` loads, `domain-modeling` does not, and you get a good interview with no paper trail. This is the failure to expect from this skill, because its `SKILL.md` is one sentence long and everything it does lives in the two skills that sentence names. If you suspect it, ask the agent directly which skills it loaded.

**Where did all my other decisions go?**
Into the conversation only, and this is the substantive gap in the skill. The glossary is not a spec, most answers do not earn an ADR, and there is no ledger tying each resolved answer through to a spec, a ticket and a test. Precise answers (ordering guarantees, negative requirements, numeric defaults) get softened into weaker prose downstream, and the result can look complete while missing the thing you actually decided. The mitigation available today is to keep the session and feed it straight to [to-spec](./to-spec.md), and to re-read the spec against your own answers rather than assuming it captured them.

**Can I point it at an existing repo that has no docs at all?**
Yes. This is the right skill for a codebase with no ADRs, no domain language and no design principles: invoke it and say "help me document my repo". It pairs well with [improve-codebase-architecture](./improve-codebase-architecture.md) when the repair is architectural as well as linguistic. Expect to steer it: it will read code and ask you about what it finds, and you are the one who says which of the words already in the codebase are the right ones.

**What should I do when the session ends?**
The skill's closing message is open-ended, which is a rough edge: it does not tell you where to go next. In the main flow the answer is [to-spec](./to-spec.md), in the same conversation. If the change is small enough to build immediately, go straight to [implement](./implement.md) instead.

**Why is it called that?**
The name is poor, and knowing why helps you remember what the skill does. "With docs" reads as though documentation were a side effect, when writing the glossary and the ADRs is half the point; something like `grill-domain-model` would describe it more honestly. It has not been renamed. If it ever is, this page moves with it.

## It's working if

- `CONTEXT.md` changes *during* the session, term by term, rather than appearing in one lump at the end.
- The glossary reads as pure vocabulary (your project's words with tight definitions) and contains no implementation detail or spec-like prose.
- Questions the codebase can answer get answered by reading the codebase, not asked of you.
- You get few or no ADRs, and the ones you get are decisions you would be annoyed to have to re-litigate.
- It challenges a word you used because your existing glossary defines it differently.

## Where it fits

`grill-with-docs` is the head of the main build chain:

```txt
grill-with-docs → to-spec → to-tickets → implement → code-review
```

It comes before anything is written down as a spec: it produces the shared understanding and settled vocabulary that [to-spec](./to-spec.md) then synthesises without interviewing you again. Its close neighbours are [grill-me](../productivity/grill-me.md), the same interview with no repo and no files, and [domain-modeling](./domain-modeling.md), the glossary-and-ADR discipline it drives; both sit on the [grilling](../productivity/grilling.md) primitive. Upstream of it, [wayfinder](./wayfinder.md) charts efforts too large for one session and can hand parts of the map back down to it.
