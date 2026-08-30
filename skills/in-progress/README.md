# In Progress

Beta. These skills are public on purpose: try them, and open an issue at [Dbaker1298/skills/issues](https://github.com/Dbaker1298/skills/issues) when one breaks or when it nearly does what you wanted. They are excluded from the plugin and the top-level README until they graduate to a stable bucket, they get no docs pages, and they can change or disappear without warning.

The plugin will not give you these. Install one directly:

```bash
npx skills@latest add Dbaker1298/skills --skill=<name>
```

Name the skill. The installer's menu lists every skill in the repository rather than the promoted set, so a run without `--skill` offers these alongside the ones that ship.

- **[loop-me](./loop-me/SKILL.md)**: Grill yourself into implementable workflow specs over multiple sessions, using the current directory as a stateful workspace. User-invoked.
- **[claude-handoff](./claude-handoff/SKILL.md)**: Hand the current conversation off to a fresh background agent that picks up the work immediately, seeded with a handoff summary via `claude --bg`. User-invoked.
- **[implement-spec](./implement-spec/SKILL.md)**: Implement a whole spec on one branch. Works the tickets as a task graph rather than a list, running implementer subagents across the ready frontier for maximum concurrency, and lands the result as a single PR. User-invoked.
- **[retro](./retro/SKILL.md)**: Suggest improvements to the coding agent's environment (steering files, coding standards, automated checks, tooling) after a session. The categories it works through are written; the process has not been run in anger yet. User-invoked.
