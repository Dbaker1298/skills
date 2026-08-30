# Curation

One triage pass over the **promoted** set, recorded so that curation is a single
decision rather than twenty four forgotten ones.

## The pass of 2026-08-29

Every promoted skill got exactly one verdict, keep or drop or defer, against one
criterion: **would I plausibly invoke this in the next month?** The pass decides
only; it removes nothing. A drop verdict would spawn its own execution ticket,
because the number of drops cannot be known before the pass is run.

Skills already in daily use are listed second, because they were reviewed last:
the unfamiliar ones are where reading the implementation actually teaches
something, and doing those first keeps the familiar ones from setting the bar.

Result: twenty four keeps, no drops, no defers, so no execution tickets follow.

### Reviewed first: not yet in daily use

| Skill | Verdict | Reason |
| --- | --- | --- |
| [teach](./skills/productivity/teach/SKILL.md) | keep | A stateful workspace for learning a topic over months, which is exactly the position I am in with skills themselves |
| [to-questionnaire](./skills/productivity/to-questionnaire/SKILL.md) | keep | Platform work runs on knowledge other teams hold, and this is the tool for pulling it out of them async |
| [prototype](./skills/engineering/prototype/SKILL.md) | keep | The cheapest way to find out whether a state model is wrong is to drive it before committing to it |
| [improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/SKILL.md) | keep | The scan I want pointed at a service the moment one accumulates enough friction to be worth deepening |
| [wait-what](./skills/productivity/wait-what/SKILL.md) | keep | Seven lines against a weekly failure, an agent message that did not land |
| [handoff](./skills/productivity/handoff/SKILL.md) | keep | These efforts already outrun a single session, so the compaction has to be deliberate |
| [wizard](./skills/engineering/wizard/SKILL.md) | keep | Provisioning and CI secrets are steps only a human can take, and re-explaining them every time is the tax this removes |
| [research](./skills/engineering/research/SKILL.md) | keep | Delegates primary source reading to a background agent while I keep working |
| [codebase-design](./skills/engineering/codebase-design/SKILL.md) | keep | The deep module vocabulary that the design skills and my own design talk both consume |
| [resolving-merge-conflicts](./skills/engineering/resolving-merge-conflicts/SKILL.md) | keep | Cheap to hold, and the situation arrives unannounced |
| [diagnosing-bugs](./skills/engineering/diagnosing-bugs/SKILL.md) | keep | The disciplined loop for the bugs that do not fall to a guess |
| [tdd](./skills/engineering/tdd/SKILL.md) | keep | Named as a pre-agreed seam by `implement`, so dropping it would break the skill I use most |
| [wayfinder](./skills/engineering/wayfinder/SKILL.md) | keep | The tool for work too big and too foggy for one session, which is the shape of every effort in this repository so far |

### Reviewed last: already in daily use

| Skill | Verdict | Reason |
| --- | --- | --- |
| [to-spec](./skills/engineering/to-spec/SKILL.md) | keep | Turns a conversation that has already happened into a spec on the tracker, with no second interview |
| [to-tickets](./skills/engineering/to-tickets/SKILL.md) | keep | Cuts a spec into tracer bullet slices with their blocking edges, which is how this repository's own work is planned |
| [implement](./skills/engineering/implement/SKILL.md) | keep | The entry point for executing a ticket, this pass included |
| [code-review](./skills/engineering/code-review/SKILL.md) | keep | Two axis review, standards and spec, on every slice before it lands |
| [triage](./skills/engineering/triage/SKILL.md) | keep | Moves issues through the five role state machine and writes the agent ready briefs |
| [grilling](./skills/productivity/grilling/SKILL.md) | keep | The interview underneath every planning skill here, and the one I reach for on its own |
| [grill-me](./skills/productivity/grill-me/SKILL.md) | keep | The user invoked door onto that interview, and the name I actually type |
| [grill-with-docs](./skills/engineering/grill-with-docs/SKILL.md) | keep | The same interview when the project has a domain worth writing down as it goes |
| [domain-modeling](./skills/engineering/domain-modeling/SKILL.md) | keep | Built this repository's own `CONTEXT.md` and its ADRs, and keeps them sharp |
| [writing-for-agents](./skills/productivity/writing-for-agents/SKILL.md) | keep | This repository's product is documents agents read, so this is the house style guide |
| [setup-david-baker-skills](./skills/engineering/setup-david-baker-skills/SKILL.md) | keep | The once per repo configuration every other engineering skill assumes |

## Verdicts outside the promoted set

The pass above covered the promoted set. A skill in another bucket gets a
verdict only when something forces the question.

| Skill | Verdict | Date | Reason |
| --- | --- | --- | --- |
| `misc/scaffold-exercises` | drop | 2026-08-30 | Scaffolded exercise directories against a course CLI that is not a public package, so it did nothing outside the course repository it was written for. Removed, with the checker allowance it needed |

## Running the pass again

Re add a section above, dated, when the set has changed enough that the question
is live again. Keep the old sections: a verdict that later proved wrong is worth
more than a clean record.
