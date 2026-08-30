## What it does

`domain-modeling` builds and sharpens a project's **ubiquitous language** while you are designing: challenging a term that conflicts with the glossary, forcing a precise word where you used a vague one, and stress-testing a relationship with a concrete scenario until the boundaries are exact.

It is the **active** discipline, not the passive one. Reading `CONTEXT.md` to borrow its vocabulary is a one-line habit any skill can do; this skill is for when you are *changing* the model. That is what makes it interrupt. It writes a resolved term into `CONTEXT.md` at the moment it is resolved, in the middle of the conversation, rather than producing a tidy glossary at the end, because the batched version is a summary of a session, and the inline version is the session's actual output.

## When to reach for it

Type `/domain-modeling`, or the agent reaches for it automatically when a task fits. Automatic invocation is the weakest part of the skill: when `grill-with-docs` or `wayfinder` name it alongside `grilling`, a model can load one and quietly skip the other. If a grilling session runs and `CONTEXT.md` is untouched at the end, that is what happened; invoke it by name alongside the other skill.

Reach for it when the *words* are the problem:

| The situation | The move |
| --- | --- |
| Two people mean different things by "cancellation" | `domain-modeling`: pick the canonical term, list the other under `_Avoid_` |
| "Account" is doing three jobs in three files | `domain-modeling`: split it into Customer and User |
| You just made a hard-to-reverse architectural choice | `domain-modeling`: it offers an ADR, if the choice clears the bar |
| The module's *shape* is the problem: where the seam goes, how deep the interface is | [codebase-design](./codebase-design.md) |
| You want the whole plan interrogated before you build | [grill-with-docs](./grill-with-docs.md), which drives this skill underneath |
| You want a term looked up, not changed | Nothing. Read `CONTEXT.md`. It is a file. |

## Prerequisites

None up front. The skill writes into two places and creates both lazily:

- **`CONTEXT.md`** at the repo root, created by the first resolved term. In a repo with a `CONTEXT-MAP.md` at the root, terms go into the per-context `CONTEXT.md` the map points at instead.
- **`docs/adr/`**, created by the first ADR that clears the bar.

Nothing needs to exist before you start, and nothing is created speculatively.

## Two artifacts, two bars

The glossary and the ADR are held to different standards, and conflating them is what goes wrong with this skill.

| | `CONTEXT.md` | `docs/adr/NNNN-slug.md` |
| --- | --- | --- |
| Holds | Terms. What a thing **is**, in one or two sentences, with rejected synonyms under `_Avoid_` | One decision, in one to three sentences: context, choice, reason |
| Bar to write | A vague term became canonical | **All three**: hard to reverse, surprising without context, the result of a real trade-off |
| Written | Inline, the moment the term is settled | Offered, not assumed |
| Never holds | Implementation details, a spec, a scratch pad, general programming concepts | A diary of every choice made this session |

Miss any one of the ADR's three tests and there is no ADR. An easily-reversed decision will just get reversed; an unsurprising one is nobody's question; one with no real alternative records that you did the obvious thing.

The `CONTEXT.md` rule is the one to actually hold onto, because it is the one most easily broken. **It is a glossary and nothing else.** Left unchecked, a model treats "write to `CONTEXT.md`" as permission to persist every answer you give, and the file turns into a running spec. Expect this rather than hoping against it: the instruction to keep the file a glossary is a sentence in a skill, and a session that has just produced a decision will look for somewhere to put it.

## Cross-referencing, and where it stops

The move that makes the skill click: when you state how something works, it checks the code and surfaces the contradiction. *"Your code cancels entire Orders, but you just said partial cancellation is possible, which is right?"* The language and the code are made to agree, out loud, before either is changed.

The limit is worth knowing. It cross-references **code** and the committed `CONTEXT.md`/ADRs, and nothing else. It does not search your issue tracker, so a naming collision that was argued out and deliberately settled in a closed issue months ago gets surfaced as if it were new. Nothing in the skill will send it looking, so tell it where to look. Put the instruction in your repo's `CLAUDE.md`, which an agent loads as project context whatever skill is running, and a settled argument stays settled.

## Common questions

**My `CONTEXT.md` is 500 lines. 1,000. 3,000. What do I do?**
The size is a symptom, not the disease: the file has absorbed implementation detail and decisions that were never glossary material. The fix is a direct instruction: `/grill-with-docs make my CONTEXT.md more concise and remove any implementation details from it`. Run it against a bloated file and most of it goes. Only reach for a `CONTEXT-MAP.md` split once the file is genuinely lean and still covers two domains that a reader would not want to hold at once; splitting a bloated file just gives you several bloated files. Nothing in the skill prevents the growth in the first place, so treat trimming as periodic maintenance rather than a one-off repair.

**Why is it `CONTEXT.md` and not `GLOSSARY.md`?**
There is a real case each way. Against: the skill itself says the file is "a glossary and nothing else", and `GLOSSARY.md` would say exactly that, where "context" is the most overloaded word in the vocabulary once agents are involved. For: the name scales to the map, since `CONTEXT-MAP.md` pointing at several `CONTEXT.md` files reads naturally where `GLOSSARY-MAP.md` does not, and *context* is the standing domain-driven-design word for a bounded area of a model. You can rename it in your own copy, but every other skill in the set looks for `CONTEXT.md` by name, so a rename means patching all of them and re-patching on every update. It is not worth it for the word.

**Where did `/ubiquitous-language` go?**
It was removed, and it was not deprecated. Its job moved into `domain-modeling`, which maintains the whole model continuously rather than dumping a glossary out of one conversation. Vocabulary enforcement got more load-bearing, not less: it now runs underneath grilling, triage and mapping rather than as a separate pass you remember to do.

**How do I get a glossary for a codebase that has none?**
Ask for it explicitly rather than waiting for it to accumulate. `/grill-with-docs help me scaffold my existing repo with a CONTEXT.md` is the documented route, and expect a long interrogation: a brownfield repo holds years of vocabulary, and the questions keep coming until it has all been named. Set aside a proper session for it. Waiting for incidental use to build the glossary instead means waiting a very long time.

**Can I keep the domain model and use my own ADR format?**
Not cleanly. The glossary half and the ADR half ship as one skill, and it carries its own opinions about ADR template, location and naming, so a team that already has an established convention gets instructions that argue with its house style every time the skill runs. Two ways out:

- **Override the conventions in your repo's `CLAUDE.md`**, which an agent loads as project context whatever skill is running. Cheaper, and it survives updates to the skill.
- **Copy the skill locally and cut the ADR half out.** Cleaner to use, and yours to maintain from then on.

**Does a glossary actually earn its keep? It is one more artifact to review, and it can go stale.**
Sometimes it does not, and it is worth being honest about where. DDD gets less useful the closer it gets to the implementation: the payoff is upstream, in naming and concept alignment, not in aggregates and layer ceremony. Synonym control matters at naming boundaries: module names, table names, status enums, issue titles, CLI commands. It matters much less in ordinary prose. There is a real objection here too: domain terms compress communication *between humans* who already share them, and an agent will usually respond just as well to the plain-English description. On that reading the glossary's value is keeping you and your reviewers aligned with what the agent is doing, rather than making the agent better at doing it. On a one-day build, skip it. And an unreviewed, agent-authored glossary is worse than none: it becomes confident-sounding lore that later sessions treat as truth.

**Can it turn my vague prompts into domain language for me?**
No, and there is no plan for a skill that does. A domain language you do not understand yourself becomes meaningless drivel once written down. This skill enforces precision once you have the understanding; it does not manufacture vocabulary you do not have. The related trap is using domain words without doing the modelling: right nouns over the wrong conceptual structure produce output that reads correct and is not.

## It's working if

- It stops you mid-sentence to ask which of two things you meant, instead of picking one and moving on.
- `CONTEXT.md` changes **during** the conversation, not in a burst at the end.
- It refuses to write an ADR for something you could undo tomorrow, and says which of the three tests failed.
- New entries define what a thing *is* in one or two sentences and name the words you are giving up under `_Avoid_`.
- It quotes your code back at you when your code and your sentence disagree.
- `CONTEXT.md` gets shorter as often as it gets longer.

## Where it fits

`domain-modeling` is a **model-invoked reference** that runs *underneath* other skills more often than it runs on its own. [grill-with-docs](./grill-with-docs.md) drives it through a grilling session, [wayfinder](./wayfinder.md) loads it while charting a map, [triage](./triage.md) uses it to keep tickets in the project's own words, and [improve-codebase-architecture](./improve-codebase-architecture.md) calls it as decisions crystallise. Its closest sibling is [codebase-design](./codebase-design.md): the two are the vocabulary layer under everything else, this one for the *domain*, that one for the module's *shape*. It is also reachable directly, when you want the discipline without committing to the steps of whatever skill would normally pull it in.
