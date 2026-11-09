# Upstream tracking

This repository was seeded from [mattpocock/skills](https://github.com/mattpocock/skills)
(MIT). It is **not** a fork: it has independent history, and upstream changes are
reviewed manually rather than merged.

## Last reviewed upstream commit

`4ae2317ddb22b046e26455e4f9c9b3aaaf62212d`, reviewed 2026-11-08 (upstream 1.3.2). Ported the
behaviour fixes to the promoted skills and the wizard template, and promoted
`chief-of-staff` and `software-factory` straight into `engineering/`, although both are
still in-progress upstream (#45). Declined for now: the setup skill's offer to migrate
a legacy `CONTEXT.md` to `GLOSSARY.md` (the rename itself was declined at the previous
review), the rewrite of upstream's docs pages, and its repository housekeeping (issue
forms, triage workflows, `SCOPE.md`, `.out-of-scope/`).

Previous review: `d81f3a183412e71a5b1e84ca21bc1a35eea03a60`, 2026-10-01. Ported `pr`, and
graduated `implement-spec` and `retro` (#39). Declined: the `CONTEXT.md` to `GLOSSARY.md`
rename, and the removal of `resolving-merge-conflicts`.

## Reviewing what changed upstream

```sh
git fetch upstream
git diff 4ae2317ddb22b046e26455e4f9c9b3aaaf62212d..upstream/main -- skills/ docs/
```

Start from the SHA recorded above, not the seed. Read the diff, port anything worth having by hand, then update the SHA and date
above. Do not merge or rebase onto `upstream/main`: this repository is expected
to diverge, and merges would replay decisions that were made deliberately here.

Watch the upstream repository with **Watch → Custom → Releases** to know when
running the above is worthwhile.
