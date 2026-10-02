## What it does

`retro` looks back over a coding session and suggests improvements to the agent's **environment**, so the next run goes better. It reads the session's own record (the current one by default, or one you point it at in the session logs), finds the moments the agent struggled, and hands you a list of candidate fixes, most severe first.

It changes the environment, not the code. The bug the agent shipped, the file it took twenty tool calls to find, the rule the reviewer missed: `retro` fixes none of them in place. It asks what about the repo let them happen, and proposes the check, the pointer, or the standard that stops them happening again. It also only proposes; nothing changes until you pick a candidate.

## When to reach for it

You invoke this by typing `/retro`, and the agent won't reach for it on its own.

Reach for it at the end of a session that felt harder than it should have: the agent went looking for something for too long, made a mistake a machine could have caught, or needed information it had no way to get. A smooth session has little to teach; a painful one is where the findings are. If what you want is a verdict on the code the session produced, use [code-review](./code-review.md) instead.

## Where the findings land

Each candidate belongs to one category, and the category decides where the fix goes:

| What went wrong in the session | Fix it with |
| --- | --- |
| The agent took a long time to find a file or fact | A **navigation pointer** from a file it already reads |
| It made a mistake a tool could have caught | An automated check: lint rule, type, test, pre-commit hook, CI job |
| The reviewer missed a judgement-call mistake | A rule in `CODING_STANDARDS.md` for the reviewer agent |
| `AGENTS.md` or `CLAUDE.md` is large | Move its steering out, into standards or checks |
| A tool call was expensive for what it returned | Streamline the tool, or replace it |
| A steering file is full of lines that change nothing | Delete the **no-ops** |
| The agent needed information it couldn't reach | Widen its access: tee the dev server log to a file, give read-only access to a service |

The leading idea is that standards belong to the **reviewer**, not the implementer. The implementing agent carries the most context pressure: it explores, writes code, and debugs failures. The reviewing agent receives a diff and nothing else. So a new rule goes where there is room to apply it, in review, and never in `AGENTS.md`, which loads into every session's context window whether it is relevant or not.

Before any rule gets written, the violation is classified. A **mechanical** one (a banned API, an import shape, a file-location rule) gets a deterministic check, because a check can fail and a sentence in a standards file can't. Only genuine judgement calls, the kind no linter could ever enforce, become prose. A repo with no guardrail at all (no pre-commit hook, no CI job running lint, typecheck, and tests) is reported as a finding in its own right.

## Common questions

**Does it write the check itself, or wait for a yes?**

It waits. `retro` only proposes, and nothing changes until you pick a candidate. Deciding what deserves a permanent check takes judgement, which is why the skill is user-invoked rather than wired to run after every session. A proposed check is built like any other code, so try it against the repo before you let it block merges.

**Does it ever suggest removing a check?**

Only on the prose side. It flags no-ops in steering files, and steering in `AGENTS.md` or `CLAUDE.md` that belongs in standards or a check. It does not audit the lint rules, hooks, or CI jobs it proposed last month: it sees one session, so it cannot tell you a rule has gone noisy or outlived the bug that justified it. Pruning checks is still your job, and a rule that fires constantly on good code is the cue.

**Won't it invent generic advice to fill its categories?**

It can, and that is the thing to watch for. Every candidate is meant to come from the session's own record, so discard any you can't trace to a specific moment. The same grounding cuts the other way too: it can over-index on whatever this one session happened to be about. Treat the severity order as a first draft, since a quiet, expensive mistake can rank below a loud, cheap one.

**The agent keeps making the same mistake. Should I add a line to `CLAUDE.md`?**

Usually not, and that is where `retro` pushes back most. A line in `CLAUDE.md` loads into every session, dilutes everything else in the file, and drifts as the code changes. If the mistake is mechanical, the fix is a check that fails. If it is a judgement call, it goes in the coding standards the reviewer reads. `AGENTS.md` and `CLAUDE.md` are for navigation pointers, and little else.

**My setup has no `CODING_STANDARDS.md`. Where does it come from?**

Nothing ships the file. The first time a session turns up a judgement-call rule for the reviewer, `retro` proposes starting it, and [code-review](./code-review.md) reads it from then on. Any standards doc you already keep, such as `CONTRIBUTING.md`, works the same way.

**How is it different from `improve-codebase-architecture`?**

The input. [improve-codebase-architecture](./improve-codebase-architecture.md) needs nothing but the code and looks for structural improvements to it. `retro` needs a session history, and improves the environment the agent works in rather than the code.

## It's working if

- Every candidate points back to a specific moment in the session, not a generic best practice.
- Repeat mistakes turn into failing checks, and your `AGENTS.md` gets shorter over time rather than longer.
- A check that already existed but sat unwired shows up as the finding, rather than a proposal to build a new one.
- The next session on the same kind of task finds its way faster.

## Where it fits

`retro` is the step after the build, where the flow looks back at itself:

```txt
grill-with-docs → to-spec → to-tickets → implement → code-review → retro
```

Run it after a build worth learning from, in the same session or pointed at that session's log. A smooth build can skip it.

- [code-review](./code-review.md) is the reviewer agent `retro` most often tunes: new coding standards land where its Standards axis reads them.
- [writing-for-agents](../productivity/writing-for-agents.md) sets the writing style for every steering file and skill `retro` proposes, and `retro` loads it before it starts.
