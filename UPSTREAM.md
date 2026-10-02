# Upstream tracking

This repository was seeded from [mattpocock/skills](https://github.com/mattpocock/skills)
(MIT). It is **not** a fork: it has independent history, and upstream changes are
reviewed manually rather than merged.

## Last reviewed upstream commit

`d81f3a183412e71a5b1e84ca21bc1a35eea03a60`, reviewed 2026-10-01. Ported `pr`, and graduated `implement-spec` and `retro`
(#39). Declined for now: the `CONTEXT.md` to `GLOSSARY.md` rename, and the removal
of `resolving-merge-conflicts`.

## Reviewing what changed upstream

```sh
git fetch upstream
git diff d81f3a183412e71a5b1e84ca21bc1a35eea03a60..upstream/main -- skills/ docs/
```

Start from the SHA recorded above, not the seed. Read the diff, port anything worth having by hand, then update the SHA and date
above. Do not merge or rebase onto `upstream/main`: this repository is expected
to diverge, and merges would replay decisions that were made deliberately here.

Watch the upstream repository with **Watch → Custom → Releases** to know when
running the above is worthwhile.
