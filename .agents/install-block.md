# The canonical install block

One install story, one wording. `README.md` must say **this** and nothing else. Change it here first, then propagate.

This repository is **not** in Claude Code's official marketplace (`claude-plugins-official`, source repo `anthropics/claude-plugins-official`). Getting into that registry is a submission to Anthropic rather than anything this repository can do to itself, so there is a marketplace to add first here and updates do not arrive on their own. Both of those are the opposite of what upstream's wording said, which is why this block was rewritten rather than find-and-replaced.

## Claude Code: the plugin

The repository is its own single-plugin marketplace, via `.claude-plugin/marketplace.json`. Adding it is the first step rather than a fallback: it is the only way to reach the plugin.

<canonical-block name="claude-code">

```bash
claude plugin marketplace add Dbaker1298/skills
claude plugin install david-baker-skills@dbaker1298
```

Or, from inside a session:

```
/plugin marketplace add Dbaker1298/skills
/plugin install david-baker-skills@dbaker1298
```

The marketplace has to be added first, and it is added once. Updates are not automatic: `claude plugin marketplace update dbaker1298` refreshes the source, then `claude plugin update david-baker-skills` applies it, and a restart is required before the new version loads.

</canonical-block>

## Codex, and other agents: skills.sh

The plugin is Claude Code only. Everywhere else, [skills.sh](https://skills.sh/Dbaker1298/skills) copies editable skill files into the project. Use the whole-set form on `README.md`:

<canonical-block name="skills-sh-whole-set">

```bash
npx skills@latest add Dbaker1298/skills
```

Pick the skills you want, and which coding agents to install them on. **The installer lets you choose which skills to take: make sure `setup-david-baker-skills` is one of them.**

</canonical-block>

…and the single-skill form wherever one skill is named on its own.

<canonical-block name="skills-sh-one-skill">

```bash
npx skills@latest add Dbaker1298/skills --skill=<name>
```

```bash
npx skills@latest update <name>
```

</canonical-block>

`skills@latest` is the pinned spelling in all three.

**`docs/` pages are not a consumer of this block.** They describe one skill each and send the reader to `README.md` to install; none of them reproduces the commands above. Upstream's reason was that its published site rendered an install widget above every page. This repository has no site, so the reason is now simply that one install story in one place is the point of this file. See [writing-docs.md](./writing-docs.md).

## The two routes are exclusive

The plugin is a managed, read-only bundle you subscribe to. skills.sh writes files you own and edit. Installing both leaves the user with every skill twice: always say "pick one".

## What these commands assume

Both routes read the repository over the public internet, so **neither resolves while `Dbaker1298/skills` is private**. They are written against the state the repository is being moved toward, not the state it is in today, and go public together with it.

The skills.sh route is the less certain of the two: the service serves public GitHub repositories that contain skills, which this one will be, but that has not been exercised against this repository yet. #25 checks both end to end from a clean sandbox, and it gates publication.
