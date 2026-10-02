# In Progress

Beta. These skills are public on purpose: try them, and open an issue at [Dbaker1298/skills/issues](https://github.com/Dbaker1298/skills/issues) when one breaks or when it nearly does what you wanted. They are excluded from the plugin and the top-level README until they graduate to a stable bucket, they get no docs pages, and they can change or disappear without warning.

The plugin will not give you these. Install one directly:

```bash
npx skills@latest add Dbaker1298/skills --skill <name> --agent '*' -y
```

Name the skill, and mind the spelling: `--skill <name>` with a space. The `--skill=<name>` form is accepted and then ignored, so with `-y` it installs all 30 skills in the repository instead of the one you asked for.

- **[loop-me](./loop-me/SKILL.md)**: Grill yourself into implementable workflow specs over multiple sessions, using the current directory as a stateful workspace. User-invoked.
- **[claude-handoff](./claude-handoff/SKILL.md)**: Hand the current conversation off to a fresh background agent that picks up the work immediately, seeded with a handoff summary via `claude --bg`. User-invoked.
