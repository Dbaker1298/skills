# Drop the router rather than rename it

Every other skill in this snapshot was inherited as a tool: a procedure that
works the same whoever runs it. `ask-matt` was not. It was a **router**: one
user-invoked skill that named the others and said when to reach for each, so
the human had one skill to remember instead of the thirteen others it
indexed.

The obvious move was to rename it, the way `setup-matt-pocock-skills` became
`setup-david-baker-skills` in #12. That was rejected, and the reason is worth
recording because it is the one place in this project where a rename would
have been dishonest rather than merely mechanical.

A router is not a procedure. Its content is a judgment about how a set of
skills relate: which flow starts where, which branches matter, which two
choices people routinely get wrong. That judgment was formed by someone who
used these skills daily for months and watched other people misuse them. Its
own docs page said so plainly, calling itself a secondary source over the
skills it described and conceding that it is hand-maintained and lags the
repo. Renaming the file would have left every one of those judgments intact
and put my name on them. The setup skill's name is a label on a procedure;
a router's name is a claim of authorship over an opinion.

I have not formed that opinion yet. I have not run these skills against
enough real work to know which flows I actually use, which branches are live
for me, or which mistakes I make. Shipping a map I did not draw, under my
name, would misrepresent the one thing in this repo that is genuinely a
personal point of view.

So the skill is deleted outright rather than renamed or emptied. An emptied
router is worse than none: a skill that exists but routes to nothing is a
promise the repo does not keep. The `PHASE-BOUNDARIES.md` reference document
it carried goes with it, since it was that same ordered judgment in longer
form.

What replaces it, for now, is nothing. The `README.md`, the bucket
`README.md`s, and the docs pages already list and describe every promoted
skill; #9 made each docs page name its own immediate neighbours, so the map
survives as a distributed one, each page a node describing the edges that
touch it. That is a weaker map than a router, and deliberately so: it states
only relationships each page can vouch for, and no single file claims to
know the whole graph.

The standing rule in `CLAUDE.md` requiring the router to be re-synced
whenever a user-reachable skill changed was removed in #10. It existed only
to keep the router honest and had nothing left to guard.

This is reversible, and the condition that would reverse it is specific:
enough time using these skills on my own work that I can say which sequence
I reach for and why. A router written then would be a map of my practice
rather than a copy of someone else's, which is the only version worth
having.
