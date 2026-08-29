# Explicit `/setup-matt-pocock-skills` pointer only for hard dependencies

Engineering skills depend on per-repo config (issue tracker, triage label vocabulary, domain doc layout) seeded by `/setup-matt-pocock-skills`. Some skills cannot meaningfully function without that config: they have to publish to a specific issue tracker or apply a specific label string. Others only use it to sharpen output (vocabulary, ADR awareness) and degrade gracefully without it.

We split these into **hard-dependency** and **soft-dependency** skills:

- **Hard dependency** (`to-tickets`, `to-spec`, `triage`): include an explicit one-liner: _"… should have been provided to you; run `/setup-matt-pocock-skills` if not."_ Without the mapping, output is wrong, not just fuzzy.
- **Soft dependency** (`diagnose`, `tdd`, `improve-codebase-architecture`): reference "the project's domain glossary" and "ADRs in the area you're touching" in vague prose only. If the docs aren't there, the skill still works; output is just less sharp.

The split keeps soft-dependency skills token-light and avoids cargo-culting the setup pointer into places where it isn't load-bearing.

## Update, 2026-08-29

The hard-dependency list above is widened to five. `code-review` and `wayfinder` carry an explicit setup pointer too, and always did: the list was already inaccurate when this repository inherited it, describing three skills where the code had five.

Both were reviewed against this ADR's own test rather than waved through. Each states a fallback in the same breath as the pointer, `wayfinder` defaulting to the local-markdown tracker and `code-review` still working when handed a spec path, which is the soft-dependency shape. The pointer earns its place anyway: both write to or read from the tracker by name, so without the mapping their output goes to the wrong place rather than merely coming out fuzzy. Degrading gracefully is not the same as degrading correctly, and it is the second that this split is really about.

The three soft-dependency skills are unchanged and still carry no pointer.

Found while repairing these pointers in #13, after the setup skill was renamed.
