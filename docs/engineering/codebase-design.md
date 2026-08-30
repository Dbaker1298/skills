## What it does

`codebase-design` fixes the words you use to design a module: **module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**. It defines each one precisely, bans the loose substitutes ("component", "service", "API", "boundary"), and states the handful of principles that follow from them.

It is a reference, not a process. There is no loop to run, no artifact it produces, no checkpoint where it asks you a question. Every other skill that touches design borrows its vocabulary; on its own it gives you the language and stops. That is the thing to know before you invoke it, because a skill with no process and no stopping rule will improvise one if you point a session at it and say "go." See the questions below for what that looks like in practice.

## When to reach for it

Type `/codebase-design`, or the agent reaches for it automatically when a design task fits.

Reach for it when you already know which code you're redesigning and you need to think about its shape: where the seam goes, how small the interface can get, whether an extraction is earning its keep. It is also what you reach for to settle an argument about what a word means.

Several skills sit close to it. Which one you want depends on what the actual problem is:

| The problem | The skill |
|---|---|
| The shape of one module: its interface, its seam, its depth | `codebase-design` |
| The *words of the domain*: "account" means three things, two people mean different things by "cancellation" | [domain-modeling](./domain-modeling.md) |
| You don't yet know *which* module to redesign | [improve-codebase-architecture](./improve-codebase-architecture.md) (the survey that finds candidates) |
| You want the design argued with, not just named | [grilling](../productivity/grilling.md) |
| There's a concrete behaviour to build and you want tests that survive a refactor | [tdd](./tdd.md) |

## The vocabulary

The glossary is the skill. Every term is defined against the others, and each one comes with the word it replaces.

| Term | What it means | Don't say |
|---|---|---|
| **Module** | Anything with an interface and an implementation. Deliberately scale-agnostic: a function, a class, a package, a slice spanning tiers. | unit, component, service |
| **Interface** | Everything a caller must know to use it correctly: the type signature, plus invariants, ordering constraints, error modes, required config, performance characteristics. | API, signature |
| **Depth** | Leverage at the interface: how much behaviour a caller or a test can exercise per unit of interface they have to learn. **Deep**: a lot of behaviour behind a small interface. **Shallow**: the interface is nearly as complex as the implementation. | none |
| **Seam** | Michael Feathers' term: a place you can alter behaviour without editing in that place. It is the *location* of an interface, and where to put it is its own decision, separate from what goes behind it. | boundary |
| **Adapter** | A concrete thing satisfying an interface at a seam. Names a role, not a substance: an in-memory fake and a Postgres repo are both adapters. | none |
| **Leverage** | What callers get from depth: more capability per unit of interface learned. | none |
| **Locality** | What maintainers get from depth: change, bugs and verification concentrate in one place. Fix once, fixed everywhere. | none |

Depth is deliberately *not* defined as the ratio of implementation lines to interface lines, which is Ousterhout's own definition. That metric rewards padding the implementation. Depth-as-leverage is used instead.

## The four principles

- **Depth is a property of the interface, not the implementation.** A deep module can be built internally from small swappable parts. They just don't surface to callers. A module can have internal seams its own tests use, and one external seam at its interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If it reappears across N callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't cut a seam until something actually varies across it. A single-adapter seam is just indirection.

Two supporting files go further, and the skill reads them on demand rather than up front. [DEEPENING.md](../../skills/engineering/codebase-design/DEEPENING.md) classifies a candidate's dependencies into four categories (in-process, local-substitutable, remote-but-owned, true-external), because the category decides how the deepened module gets tested across its seam. [DESIGN-IT-TWICE.md](../../skills/engineering/codebase-design/DESIGN-IT-TWICE.md) spins up parallel sub-agents to produce three or more radically different interfaces for the same module, then compares them on depth, locality and seam placement.

## Common questions

**How do I actually build a deep module in TypeScript?**

The skill does not answer it, and that is the gap worth knowing about before you start. It defines what a deep module *is*; it says nothing about how to stop a stray import from reaching past the interface, and without a guardrail an interface erodes: a deadline-shaped exception becomes a precedent, and nothing is checking. Three mechanisms work, in rough order of what they cost you: wrap the module in a class or a closure and accept that the class grows large; make it a package in a monorepo and accept the monorepo tooling; or have a linter such as [dependency-cruiser](https://github.com/sverweij/dependency-cruiser) forbid the imports that bypass the interface. `setup-ts-deep-modules`, in the `in-progress/` bucket, takes the third route: it lays down a `src/packages/<name>/` convention where a package's root files are public and every subfolder is private, and it ships a `dependency-cruiser.config.cjs` that enforces exactly that. It is a beta skill with no docs page, so read it before you run it.

**I pointed a session at it and it burned 100k tokens redesigning things I never asked about.**

The skill is model-invoked and describes itself as vocabulary, but nothing in it hard-stops an agent from treating it as a runnable process. Tell a session to drive off `/codebase-design` alone and it reaches for the most action-shaped content it can find, which is the parallel sub-agents in `DESIGN-IT-TWICE.md`: it re-explores code, generates competing designs, and runs a long way before asking anything. None of the guardrails a driver skill has (checkpoints, one question at a time, no auto-advance) are present, because a reference has none. Name a driver skill and let this one sit underneath it: `/grill-with-docs`, `/improve-codebase-architecture` or `/tdd`, with `codebase-design` as the vocabulary.

**Where did `design-an-interface` go? And is there an `/interface-design` skill?**

`design-an-interface` was removed and absorbed into this skill. Nothing was lost: its "design it twice" technique (parallel sub-agents generating radically different designs, from Ousterhout) ships here as `DESIGN-IT-TWICE.md`. There is no separate `/interface-design` skill and none is planned: the deep-module and thin-interface philosophy that name suggests already lives here. If you came looking for either name, this is the page.

**Isn't this a file-structure convention, such as folders, barrel files, feature slices?**

No. The two are orthogonal: a deep module is about the design of the interface and about callers reaching the implementation only through it, whatever the file system looks like. You can lay down a perfectly regular tree of folders and barrel files and still have shallow modules behind it. The glossary says so directly, defining **module** as deliberately scale-agnostic: a function, a class, a package, or a tier-spanning slice. Treat the file system as a useful hint about where the modules are, never as the thing that makes them deep.

**Does `tdd` actually use this vocabulary?**

It does now. For a long time it did not. The inline deep-module notes that used to live inside `tdd` were removed in favour of this shared skill, but the pointer replacing them was never added, so `tdd` defined "seam" for itself and referenced nothing. The gap is closed: the pointer is now in the skill, reached when the shape of the interface is the open question rather than the tests. `tdd` still owns "seam" as the boundary you *test* at; this skill owns the module shape behind it.

**Does the design-it-twice pattern work in my harness?**

In wording, yes: `DESIGN-IT-TWICE.md` asks to "spawn 3+ sub-agents in parallel" without naming any one harness's tool, and the skill ships `agents/openai.yaml` next to its `SKILL.md`, so Codex loads it too. What may not travel is the capability rather than the instruction. A harness that cannot fan out to several sub-agents at once gives you the pattern serially or not at all, which makes the design phase slower and can turn it into something you drive by hand. Check what yours offers before you plan around three designs arriving together.

**Can I add my own concepts to the glossary, such as connascence, module secrets, progressive disclosure?**

You can, and the cost is worth weighing first. The glossary is deliberately small, and the skill states the reason in its opening lines: consistent language is the whole point. A term the whole team reaches for the same way earns its keep. A term used loosely is worse than no term, because it adds a word to learn without settling the argument it was supposed to settle. Add one when you have hit the confusion it resolves more than once, not because it is a good idea in the abstract.

## It's working if

- The design conversation stops producing the words "component", "service" and "boundary", and starts producing "module", "interface" and "seam".
- Someone can point at a proposed extraction and say whether it passes the deletion test, without hedging.
- A proposed seam comes with a second adapter named, not just the first one.
- Discussion of an interface covers invariants, ordering and error modes, not only the type signature.
- Invoking it does not start a session. If the agent begins reading files and proposing refactors off the back of `/codebase-design` alone, it has mistaken the reference for a driver.

## Where it fits

`codebase-design` is a **reach-for-it-anytime standalone**, and the vocabulary layer underneath the engineering skills rather than a step in any chain. Its closest neighbour is [domain-modeling](./domain-modeling.md), the parallel reference for the *problem domain*'s words rather than the module's shape. The two are usually wanted together, since naming a deep module well needs both. [improve-codebase-architecture](./improve-codebase-architecture.md) is the other: it surveys a codebase for deepening candidates and writes every one of them in this glossary, so it finds the module and this skill is the bench you design it on.
