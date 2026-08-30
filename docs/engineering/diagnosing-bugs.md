## What it does

`diagnosing-bugs` runs a six-phase diagnosis on a hard bug or a performance regression: build a repro, minimise it, rank hypotheses, instrument, fix with a regression test, clean up.

It will not let the agent form a theory until a **tight** feedback loop exists: one named command, already run once, that goes red on *this* bug and green when it is fixed. The default behaviour of a coding agent handed a bug report is to read code and guess; this skill blocks that. If no red-capable command exists, there is no Phase 2. That single gate is what the skill is for. Everything after it (bisection, hypothesis-testing, instrumentation) is mechanical once the signal exists.

## When to reach for it

Type `/diagnosing-bugs`, or the agent reaches for it on its own when a task fits: it is model-invoked, and fires on "diagnose" / "debug this" or on a report that something is broken, throwing, failing, or slow.

Reach for it on the hard ones: a bug that resists a first look, an intermittent flake, a regression that crept in between two known-good states. It is heavy by design, and the wrong tool for a question you want answered in one message.

| Your situation | Where to go |
| --- | --- |
| A specific defect you can describe as a symptom | This skill |
| A slow endpoint or a timing regression with a known before-and-after | This skill: it has a performance branch (measure a baseline, then bisect) |
| "Where are the bottlenecks in this codebase?", no specific symptom | Not this skill. It diagnoses one known failure, it does not audit |
| A raw bug report from someone else, not yet confirmed or written up | [triage](./triage.md) first |
| Throwaway code to answer a design question, not chase a defect | [prototype](./prototype.md) |
| Building a planned behaviour test-first | [tdd](./tdd.md) |
| No good seam exists to lock the bug down | [improve-codebase-architecture](./improve-codebase-architecture.md): this skill hands off there itself |

## The tight loop is the skill

Phase 1 gets disproportionate effort because it is the only phase that is hard. The skill gives a ladder of ways to construct the loop, roughly in order of preference:

1. A failing test at whatever seam reaches the bug.
2. A curl or HTTP script against a running dev server.
3. A CLI invocation with a fixture input, diffed against a known-good snapshot.
4. A headless browser script asserting on DOM, console, or network.
5. A replayed capture: a saved request, payload, or event log, run through the code path in isolation.
6. A throwaway harness: a minimal subset of the system, one function call.
7. A property or fuzz loop, for "sometimes wrong output".
8. A bisection harness you can hand to `git bisect run`.
9. A differential loop: same input, old version against new.
10. A human-in-the-loop bash script, last resort. The skill ships `scripts/hitl-loop.template.sh` for this: the agent runs the script, you follow prompts in your terminal, and your answers come back as parseable output.

*A* loop is not the goal. **Tight** is: fast (seconds), deterministic (same verdict every run), sharp (asserts your exact symptom, not "didn't crash"), and agent-runnable unattended. A 30-second flaky loop is barely better than none. For a bug that only shows up sometimes, the target is not a clean repro but a **higher reproduction rate**: loop the trigger, parallelise, add stress, inject sleeps, until the flake rate is high enough to debug against.

When it genuinely cannot build one, it is instructed to stop and say so, list what it tried, and ask you for environment access, a captured artifact, or permission to add temporary instrumentation. It should not proceed to hypothesise anyway.

## The gates between phases

The phases are gates, not a checklist. Each one refuses to open until something specific is true.

| Gate | What has to be true |
| --- | --- |
| Into Phase 2 | A named command, already run and pasted with its output, that can go red on this bug |
| Into Phase 3 | The repro is reproduced *and* minimised: every remaining element is load-bearing |
| Into Phase 4 | 3–5 ranked, falsifiable hypotheses exist, each stating its prediction, shown to you before any is tested |
| Into Phase 5 | Probes map to a specific prediction, one variable at a time, every debug log tagged `[DEBUG-a4f2]`-style so cleanup is one grep |
| Done | Original repro no longer reproduces, instrumentation gone, and the hypothesis that turned out correct is written into the commit message |

Phase 5 has an escape hatch worth knowing about. The regression test is written before the fix, but only if a **correct seam** exists for it: one where the test exercises the real bug pattern as it occurs at the call site. Where the only available seam is too shallow, the skill is told to say so rather than write a test that gives false confidence. That absence is itself the finding, and it is what routes the post-mortem to `improve-codebase-architecture`.

## Common questions

**It fires on quick questions where I just wanted a direct answer.**
Look at what it fires on. The description reads "use when the user says diagnose/debug this, or reports something broken/throwing/failing/slow", which covers most of how anyone mentions a problem in passing. Then look at what happens once it fires: the skill's opening line is to skip phases only when explicitly justified, so it starts building a reproduction loop before it offers you anything. A wide trigger and a committing body is a bad combination for a one-line question, and a model that reaches for skills readily will land there more often than one that does not. Two fixes, both yours: say what you want ("just answer this, don't diagnose"), or turn off model invocation for this skill in your harness if the shape keeps recurring.

**Can I point it at a codebase and ask where the performance problems are?**
No. It diagnoses one failure you can already name. Its performance branch is for a regression with a symptom (establish a baseline measurement, then bisect, measure first and fix second), and every phase after the first assumes there is a specific red you are chasing. Nothing here does the proactive sweep, and pointing this skill at one gives you a thorough investigation of whatever it happened to notice first.

**Does it stop and ask me before it writes the fix?**
No. Phase 3 is the only human checkpoint in the whole run: the ranked hypothesis list is shown to you before any of it is tested, and the skill explicitly says not to block on it, proceeding on its own ranking if you are away. The gate into Phase 5 is a quality bar the agent checks against itself (probes mapped to predictions, one variable at a time, logs tagged), not a stop for you, so it can be writing the fix before you have agreed with its root cause. If you want that gate, ask for it when you invoke the skill.

**I already ran `/triage` on this bug report. Is this the same work again?**
Partly, and neither skill admits it. `triage` verifies before it briefs: a bounded "is this real, and roughly where does it live" pass, which is a shallow instance of what Phase 1 and Phase 2 do thoroughly. Neither skill's text mentions the other, so nothing tells you the overlap is there or hands the earlier work forward. Running triage first is not wasted, because its reproduction attempt is usually most of Phase 1's raw material, but expect to redo it properly here rather than to have it carried over.

**Will the repro output it pastes leak secrets?**
Less than you would expect, because the skill leads with the problem. `## Redact` is its first section, ahead of every phase: redact every secret before showing anything and write `<REDACTED>` in its place, build loops against environment variables so the credential stays in the environment rather than in what gets shown, and quote only the signal-carrying lines out of a captured artifact, since HAR files and log dumps carry auth headers as a matter of course. It also tells the agent to stop and ask you when the redacted output is not enough to diagnose, rather than quietly widening what it pastes. That is instruction rather than enforcement: nothing scans the output, and the agent decides what counts as a secret. So keep your own eye on it, particularly before anything lands in an issue or a PR.

**My security scanner flagged this skill as high risk.**
Check what it is reacting to before you act on it. This skill ships a shell script, `scripts/hitl-loop.template.sh`, alongside instructions to run it and to curl a running dev server. A shipped `.sh`, plus text telling an agent to execute it, plus outbound HTTP is the shape a static scanner is built to flag, and it will flag it without opening the file. Open it: it is a short loop of `read -r` prompts that pauses for human input, it is not even marked executable, and its own header tells you to copy it and run it with `bash`. What you are looking at is a rating of the capability surface, not a finding about behaviour, so read the script and decide for yourself.

**What happened to `/diagnose`?**
Renamed to `/diagnosing-bugs`. The old name no longer exists. Anything of yours that chains `/diagnose` (a wrapper skill, a saved prompt) needs updating.

## It's working if

- It shows you a command and its red output before it offers a single theory. If theory arrives first, the skill is not running.
- The failure it reproduces is the one you reported, not a nearby one it found on the way.
- It shrinks the repro before it starts guessing, and can tell you why each remaining piece is load-bearing.
- You are shown a ranked list of 3–5 hypotheses, each with a prediction you could falsify, before any of them is tested.
- Every debug log it adds carries a tag like `[DEBUG-a4f2]`, and a grep for that tag comes back empty when it declares done.
- The commit or PR message names which hypothesis was right.
- When it cannot lock the bug down with a test, it says so plainly instead of writing a shallow one.

## Where it fits

`diagnosing-bugs` is a reach-for-it-anytime standalone. You drop into it when something is broken and drop out when the fix and its regression test are in; it holds no state and needs no prior setup.

Two neighbours matter. [improve-codebase-architecture](./improve-codebase-architecture.md) takes the handoff when the real finding is that the code has no seam to lock the bug down; the recommendation is made after the fix is in, when there is more information. [triage](./triage.md) sits upstream of it for bugs that arrive as raw reports from other people, and does a shallower version of the same first two phases.
