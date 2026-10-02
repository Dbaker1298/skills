## What it does

`pr` is the shape a pull request body should take: a **Summary** that shows the change, **Evidence** that it works, and a **Merge Danger** call on how risky it is to land. It is a format reference, not a workflow. It does not push a branch, open the PR, or decide what goes into it; it tells the agent what the body should look like once it is writing one.

The summary is a picture, not a paragraph. Where a default PR body narrates the diff in prose, this one picks the **smallest view** that makes the key point clear (pseudocode, a call tree, a component tree, a file tree, a Mermaid diagram, or a shaped diff) and keeps the words around it brief. The reviewer already has the diff open; the body's job is to show them its shape before they read it.

## When to reach for it

Type `/pr`, or the agent reaches for it automatically whenever it is writing a PR body.

| Your situation | Reach for |
| --- | --- |
| A branch is ready and needs a body a reviewer can scan | `pr` |
| The code is written but nobody has reviewed it yet | [code-review](./code-review.md) first, then `pr` |
| The PR is open and review comments are coming back | Nothing in this set; `pr` only writes the body |

## The template

Three sections, in this order:

- **Summary**: one or more small visuals, each placed next to the short text it supports. Use one, sometimes several, rarely all of them. Keep only the calls, files, props, and boundaries the reviewer needs.
- **Evidence**: a before and after. A screenshot is the strongest evidence when the change is visual and the environment can take one; otherwise the exact test that failed and now passes, written as pseudocode, or the console output that changed.
- **Merge Danger**: whether the change is a **one-way door** or a **two-way door**, and its **blast radius**. A two-way door is cheap to walk back; a one-way door (a destructive migration, a public API removal, a hard-to-reverse decision) is not. Blast radius names what could break if the change is wrong: layout shift, consumers of an API, mobile responsiveness.

The door call is the leading idea. It turns "is this safe to merge?" from a gut feeling into a stated claim the reviewer can disagree with, and it tells them where to spend their attention: a two-way door with a small blast radius can be skimmed; a one-way door deserves a slow read.

## Common questions

**Can I trust the agent's own door call?**

Not blindly, and that is the point of stating it. The agent that wrote the change is the one grading it, and a self-report is most comfortable exactly when it says "two-way, small blast radius". Reversibility is also often invisible in the diff: rolling back a commit does not unsend a batch of emails, and a flagged rollout stays two-way only until the first write lands in the new format. The skill gives the agent a definition (destructive actions and hard-to-reverse decisions are one-way), not a checklist, so read the Merge Danger section hardest of all. Two things help: make sure the agent has the issue or spec in front of it, not just the diff, and write down the changes your repo always treats as one-way (schema migrations, anything that ships outward or deletes) where the agent will read them before it makes the call.

**Does it open the PR for me?**

No. `pr` covers only the body. [implement](./implement.md) ends by committing to the current branch and opens nothing. [implement-spec](./implement-spec.md) is the exception: it opens a draft PR when your issue tracker closes work through PRs or when you ask for one. Because `pr` is model-invoked, any time you ask the agent to open a PR, this is the shape its description takes.

**My repo already has a PR template. Which one wins?**

Neither, by default: `pr` carries its own template and does not look for `.github/pull_request_template.md` or anything like it, so left alone the agent is holding two competing instructions for the same document. Settle it in your repo's agent docs, for example by filling the repo template and putting Summary, Evidence and Merge Danger under it.

**Why doesn't the Mermaid diagram render?**

The output is a markdown PR body. GitHub and GitLab render Mermaid blocks in a PR description, but a terminal does not, so the diagram looks like raw text while the agent is still showing it to you locally. Mermaid is one of six views; a call tree, file tree or shaped diff reads the same everywhere.

**My change has no UI. What goes in Evidence?**

Everything except the screenshot. For a migration, a background job or a refactor, the evidence is the exact test that failed before and passes now, or the console output that changed. "Tests are green" on its own is a claim, not a before and after.

## It's working if

- You can tell what the PR changes from the Summary visual alone, before opening the diff.
- The body has no preamble: it starts at the Summary heading.
- The Evidence section shows a before and an after, not a claim that tests pass.
- Every PR states a door and a blast radius, and the one-way doors are the ones you slow down on.

## Where it fits

`pr` sits after review when the build goes up as a pull request: `implement → code-review → pr`. It is model-invoked, so it also fires on its own any time the agent writes a PR body outside that chain.

- [code-review](./code-review.md) runs before it, because a PR body should describe a diff that has already been reviewed.
- [implement](./implement.md) and [implement-spec](./implement-spec.md) produce the commits the body describes.
