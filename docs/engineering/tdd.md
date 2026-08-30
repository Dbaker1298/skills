## What it does

`tdd` builds a feature or fixes a bug test-first: one failing test, then just enough code to pass it, then the next behaviour. It carries the standards that make that loop produce tests worth keeping: what a good test is, where tests go, what mocks are for, and the three anti-patterns that quietly ruin a suite.

It writes no test at a seam you have not agreed to first. Before any test exists, it names the public boundaries it intends to test at and stops for your confirmation, because testing effort is finite and this is where you spend it on the critical paths instead of on every edge case. The other thing to know is that `tdd` is a **reference**, not a driver. It holds the rules of the loop, and something else (you, or [implement](./implement.md)) runs the session that applies them.

## When to reach for it

Type `/tdd`, or the agent reaches for it automatically when a task fits: building a feature or fixing a bug test-first, or when you say "red-green-refactor".

Reach for it when there is a concrete behaviour to build, with an input and an observable output, and you want tests that survive a refactor.

| Your situation | Where to go |
| --- | --- |
| A behaviour with defined inputs and outputs (business logic, a request/response contract, a transformation, validation) | `tdd` |
| The behaviour isn't pinned down yet | [to-spec](./to-spec.md), which also agrees the test seams before any code is written |
| The question is really the shape of the interface, not the tests | [codebase-design](./codebase-design.md) |
| You have a spec or tickets and want the whole build run for you | [implement](./implement.md), which drives `tdd` per ticket |
| Config, wiring, glue, type annotations, straight CRUD delegation | Nothing here fits well; see the open gap below |

That last row is a real hole, not a stylistic preference. The skill decides *where* the seams go; nothing in it decides *whether* a change is worth the loop at all. Run it on a change with no independent source of truth to assert against and you get a test that restates the implementation: the tautological anti-pattern the skill itself warns about, arrived at from the other direction. Nothing in the skill closes that hole, so the judgement is yours or your `CLAUDE.md`'s: decide what is worth the loop before you start it.

## Prerequisites

[codebase-design](./codebase-design.md) needs to be installed. `tdd` used to carry its own deep-module and interface-design notes; in v1.0 those were deleted in favour of the shared skill, and `tdd` now leans on it for interface-design vocabulary. Nothing else; the skill is stateless and writes no files of its own.

## The loop, and the seam it runs at

Three words carry this skill.

**Red-green.** Write the failing test, then only enough code to pass it. No anticipating the test after next. There is no refactor phase: it was dropped in June 2026 because agents essentially never performed it, and because review and implementation work better as separate sessions. Refactoring belongs to [code-review](./code-review.md).

**Vertical slice.** One seam, one test, one minimal implementation, then repeat, the first cycle being a **tracer bullet** that proves a single path end to end. The opposite is horizontal slicing: all the tests first, then all the code. Bulk tests verify *imagined* behaviour, they check the shape of things rather than what a user does, and they commit you to a test structure before you understand the implementation.

**Pre-agreed seam.** A seam is the public boundary you observe behaviour at without reaching inside. The rule is absolute: no test at an unconfirmed seam. In the full chain the seams are agreed earlier, during [to-spec](./to-spec.md): "`/tdd` is told to only work at pre-agreed test seams, `/code-review` checks that only agreed-upon test seams were used." Invoked on its own, `tdd` asks you directly.

The three anti-patterns it is written to prevent:

| Anti-pattern | The tell |
| --- | --- |
| Implementation-coupled | The test breaks when you rename an internal function, though behaviour did not change. Mocked internal collaborators, asserted call counts, database queries used to verify instead of the interface. |
| Tautological | The expected value is computed the way the code computes it, so the test passes by construction. Expected values have to come from somewhere else: a known-good literal, a worked example, the spec. |
| Horizontal slicing | A batch of tests landed before any implementation. |

Mocks are for system boundaries only: external APIs, time, randomness, sometimes the filesystem or the database. Not your own modules.

## Common questions

**Why doesn't it refactor? The description says "red-green-refactor".**

Because the refactor step was removed and the description was not. The skill's own rules say so outright: refactoring is not part of the loop, it belongs to the review stage. The removal was deliberate, on the grounds that keeping implementation and review in separate sessions produces better code than a third step an agent skips anyway, and whether the result still counts as TDD by the book matters less than that. The description still carries "red-green-refactor" because that is the phrase people type to fire the skill, so it keeps working as a trigger. What you get is red → green, and refactoring in [code-review](./code-review.md).

**It asked me to choose a test seam and I had no idea which to pick.**

The skill asks one question, "what's the public interface, and which seams should we test?", and then refuses to write a test at a seam you have not confirmed. It gives you nothing to answer it with: no note on what a component-level seam catches that an integration seam misses, no sense of what each costs to run. You are choosing between labels. Ask for the trade-offs before you answer, in those terms, and the gate does its job. It is also why the chain agrees seams up front in `to-spec`, where you have the whole feature in view rather than one prompt at the moment you least want to think about it.

**It wrote the implementation before the test, even though the skill says red first.**

It happens, and the skill is written to live with it rather than to prevent it. No instruction makes an agent comply every time; a model that has read "one test at a time, watch it fail for the right reason" can still fall back on its ordinary habit of writing the code first. Tightening the wording buys little and costs flexibility elsewhere, and the loop is worth running even when it is followed loosely, because the tests you end up with are better than the ones you would have written after the fact. Where strict adherence matters for a particular slice, watch the run rather than trusting the skill to enforce it.

**Should it write browser or end-to-end tests first?**

Usually not, and the skill will not stop it. A browser or end-to-end test is slow enough that the red → green loop stops paying for itself, and pointed at behaviour that does not exist yet it gives you a long, expensive red that teaches you nothing: the agent re-runs it, and the likeliest conclusion it draws is that the *test* is broken. Declare in your repo's `CLAUDE.md` that browser tests are written once the behaviour works, and the skill will follow your file.

**Does `/tdd` replace `/implement`, or the course's `/do-work`?**

No. `/tdd` documents the methodology; `/implement` is a very simple work→feedback→commit loop and is the direct stand-in for `/do-work`. The course's single `/do-work` step is now split across `/implement`, `/tdd` and `/code-review`. If you are asking which one to run against a ticket, the answer is almost always `/implement`.

**Where did the deep-modules and interface-design guidance go?**

Into [codebase-design](./codebase-design.md) in v1.0, generalised so several skills share one vocabulary. `refactoring.md` left at the same time; refactoring is now [code-review](./code-review.md)'s job, and that skill carries the Fowler smell baseline.

**Does it know about my other tickets?**

No. It has no view of the issue graph at all, so run against one ticket it will happily propose work that belongs to a sibling. Widening its view is not the fix and is not this skill's job: `tdd` is a loop around one behaviour, and a loop that reads your whole backlog is a different tool. Pass the spec alongside the ticket and it has the surrounding shape without the licence to build it; right-size the tickets in the first place and the problem mostly stops arising.

## It's working if

- It stops and names the seams it intends to test at, and waits, before any test file exists.
- One test appears, goes red, gets just enough code to pass, and only then does the next test appear, not a batch of tests followed by a batch of code.
- Test names read as capabilities ("user can checkout with valid cart"), not as internals ("checkout calls paymentService.process").
- Expected values in assertions are literals you can trace to the spec, not values recomputed the way the code computes them.
- Renaming an internal function breaks nothing in the suite.
- Mocks appear only at external boundaries (the payment API, the clock) and never around your own modules.

## Where it fits

`tdd` is the engine inside the build step of the main chain, rather than a step of its own:

```txt
grill-with-docs → to-spec → to-tickets → implement → code-review
```

[to-spec](./to-spec.md) agrees the test seams up front, [implement](./implement.md) drives `tdd` per ticket, and [code-review](./code-review.md) checks afterwards that only the agreed seams were used, and owns the refactoring `tdd` no longer does. Its other neighbour is [codebase-design](./codebase-design.md), the shared source of the seam and deep-module vocabulary `tdd` speaks. You can also reach for it on its own, whenever there is a concrete behaviour to build and no full spec in play.
