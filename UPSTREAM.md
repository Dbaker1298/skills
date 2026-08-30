# Upstream tracking

This repository was seeded from [mattpocock/skills](https://github.com/mattpocock/skills)
(MIT). It is **not** a fork: it has independent history, and upstream changes are
reviewed manually rather than merged.

## Last reviewed upstream commit

`6654f6b60cd9d5be8b54c6fafe44346dabeb3b76`, reviewed 2026-08-29 (the seed snapshot).

## Reviewing what changed upstream

```sh
git fetch upstream
git diff 6654f6b60cd9d5be8b54c6fafe44346dabeb3b76..upstream/main -- skills/
```

Read the diff, port anything worth having by hand, then update the SHA and date
above. Do not merge or rebase onto `upstream/main`: this repository is expected
to diverge, and merges would replay decisions that were made deliberately here.

Watch the upstream repository with **Watch → Custom → Releases** to know when
running the above is worthwhile.
