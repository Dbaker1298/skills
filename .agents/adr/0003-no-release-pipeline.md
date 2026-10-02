# No release pipeline

Upstream ships this repo as a versioned artifact: changesets accumulate one
entry per merged change, a GitHub Actions workflow opens a version pull
request, `CHANGELOG.md` grows a section per release, and a sync script copies
the resulting version into `.claude-plugin/plugin.json`. That machinery exists
because upstream's plugin is listed in Claude Code's official marketplace,
where a version bump is how installed users learn there is something new.

This repo inherited all of it and operates none of it. The listing is not
inheritable (see [0002](./0002-ship-as-a-claude-code-plugin.md)), so nothing
downstream reads a version number here, and no consumer is waiting on a tag.
A changelog under those conditions is not a record of anything: the entries
that arrived with the snapshot describe upstream's history, and a first
version cut here would claim changes it never contained.

So the pipeline is removed rather than adapted: `.changeset/`, the release
workflow, and `CHANGELOG.md` are deleted. The package manifest and lockfile
went with them, along with the script that reconciled the manifest's version
against the plugin's, leaving `.claude-plugin/plugin.json` as the only place
a version is written.

What replaces it, for now, is nothing. Git history is the record of what
changed, `UPSTREAM.md` records how far upstream has been reviewed, and the
skills.sh route serves whatever is on `main` rather than a published version.

This is reversible, and the conditions that would reverse it are specific:
a marketplace listing, or enough consumers pinning a version that "what
changed since I installed" stops being answerable by pointing at the log.
Reintroducing changesets at that point is a fresh decision on a repo whose
history is its own, which is a better starting position than carrying a
pipeline nobody runs and a changelog that describes someone else's work.

## Update, 2026-10-01

"Nothing downstream reads a version number here" is false. Claude Code reads
`version` in `.claude-plugin/plugin.json` to decide whether an installed copy
is stale. #40 added three promoted skills at an unchanged `0.1.0`, and an
install made before it then ran `claude plugin marketplace update` and
`claude plugin update`, was told it was already at the latest version, and
kept the old skill set. Bumping the version in the same sandbox delivered
them. See #41.

The decision stands: there is still no changelog, no changesets, and no
release workflow. What changes is that the one version left is load-bearing,
so it is bumped by hand in every PR that changes a promoted skill, under the
rule `CLAUDE.md` states. The skills.sh route is unaffected, since it reads
`main` and never looks at the version.
