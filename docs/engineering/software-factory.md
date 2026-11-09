## What it does

`software-factory` is a shared vocabulary for designing a **software factory**: a system of agents that turns tickets, PRs and schedules into merged code, running on remote infrastructure you choose. It gives you and the agent one set of words for the parts (task, trigger, run, runner, orchestrator, and the services they plug into) so a design conversation doesn't drift between "job", "workflow" and "action" for the same thing.

It designs the factory and builds nothing. There is no setup step and no code generated. It is a glossary plus a method for the design conversation, along with short surveys of the products that can fill each slot, and it finishes when every slot has a product and every task has answers to the design questions.

## When to reach for it

You invoke this by typing `/software-factory`, and the agent won't reach for it on its own. Call it alongside [grill-me](../productivity/grill-me.md), which drives the interview while this skill holds the words.

Reach for it when you are deciding how to put agents to work on a repo unattended: triaging incoming tickets, reviewing PRs automatically, implementing tickets as they become ready, or running a migration on a clock. For running a long goal from one interactive session instead, use [chief-of-staff](./chief-of-staff.md).

## Tasks, runs and services

The design has two halves:

| Half | What it is |
| --- | --- |
| **Services** | Slots filled by a product: ticket tracker, ticket source, git host, orchestrator, runner, observability platform |
| **Tasks** | Kinds of work defined once and run many times (explore, implement, review, rework, decompose), each **run** started by a **trigger** and executed on a disposable **runner** |

A run never waits for a human. It ends, and the human's later change to a ticket or PR triggers a new run. That rule is what keeps every run a black box with a clean start and finish.

## Start slow

The skill's leading idea is that every trigger is an accelerator, and accelerators without brakes make a slop cannon. The brakes are automated checks, automated review, and human review. A design adds one automated trigger at a time, throttles it at first, keeps human review on every PR, and caps every loop at a few tries before a human steps in.

## Common questions

**Its glossary says "ticket tracker" and avoids "issue tracker". Which do I use?**

Inside a factory design, "ticket tracker", because the skill holds you to its own words. Everywhere else in this set the house term is still issue tracker, as [setup-david-baker-skills](./setup-david-baker-skills.md) configures it. The two name the same kind of service seen from different conversations.

**Does it recommend specific products?**

Only as a starting point. Each slot has a short survey grouped by type, with the questions that decide the choice, and the agent is told to research the current options itself rather than trust the survey. The default advice is to buy the services and build the tasks, and to prefer an off-the-shelf ticket tracker.

## It's working if

- The conversation settles on one word per part, and the agent corrects a drifting synonym to the canonical term.
- The design starts from a problem you have (untriaged tickets, PRs waiting for review), not from the factory.
- Every task in the design answers what triggers it, what it reads and writes, what it triggers next, where a human re-enters, and what stops two runs doing the same work.

## Where it fits

`software-factory` is a reach-for-it-anytime vocabulary layer for one kind of design conversation.

- [grill-me](../productivity/grill-me.md) runs the interview this skill gives words to.
- [chief-of-staff](./chief-of-staff.md) is the interactive counterpart: one session pursuing a goal, where the factory is many unattended runs.
