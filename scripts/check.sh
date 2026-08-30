#!/usr/bin/env bash
set -euo pipefail

# Checks this repo's structural invariants: the rules CLAUDE.md states in prose
# but nothing enforces. Run it before pushing, and after anything that adds,
# removes, renames, promotes, or demotes a skill.
#
#   scripts/check.sh
#
# It reads and reports. It never writes, so a failing run leaves the tree
# exactly as it found it and the fix is always yours to make.
#
# Every rule runs on every invocation and violations are collected rather than
# thrown, so one run tells you everything that is wrong. Stopping at the first
# failure would turn a broken rename into a fix-run-fix loop, one violation at
# a time, which is how a checker becomes something people skip.
#
# Rules are added by later tickets: write a function, append its name to RULES.
# A rule reports through `violation` and returns normally; a rule that cannot
# evaluate at all reports that as its own violation rather than exiting. Rules
# check the commands they run rather than leaning on errexit (see the driver).
#
# No dependencies, by construction. Like scripts/link-skills.sh this reads the
# plugin manifest with grep rather than a JSON parser, so the checker runs in a
# clean clone with nothing installed. This repo has no package manifest (see
# .agents/adr/0003-no-release-pipeline.md); anything the checker needs beyond
# coreutils has to earn its way back in. The one rule that needs a tool,
# plugin validation, delegates to the Claude CLI and reports itself skipped
# where that is absent, so the promise holds on a machine without it.
#
# scripts/link-skills.sh parses the same manifest for the same set. Two
# standalone readers is under the rule of three and both scripts are meant to
# run alone, so they stay separate. A third one should become a shared helper
# rather than a third variant.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

violations=()
skips=()

violation() {
  violations+=("$1")
}

# For a check that could not run because the environment lacks something,
# rather than because this repo is wrong. A skip is reported every time and
# never counts as clean, but it does not fail the run: a checker that stays red
# for a reason the reader cannot fix is one they learn to stop reading.
# Set CHECK_REQUIRE_ALL=1 to turn every skip into a violation, which is what a
# CI job wants.
skip() {
  if [ "${CHECK_REQUIRE_ALL:-}" = "1" ]; then
    violations+=("$1 (CHECK_REQUIRE_ALL=1)")
  else
    skips+=("$1")
  fi
}

MANIFEST=".claude-plugin/plugin.json"

# The promoted set, one "./skills/<bucket>/<name>" entry per line.
#
# Reads the skills array only, rather than every ./skills/ string in the file:
# a whole-file grep would also match a path quoted in some future description
# or command field and treat it as an entry. The first sed takes the array's
# lines, the second drops everything up to the opening bracket so the "skills"
# key itself is not mistaken for an element.
#
# Prints nothing when the manifest is missing or unreadable, rather than
# letting sed complain to stderr underneath the report. Callers distinguish
# nothing-found from all-fine by counting what they get; reporting an
# unreadable manifest belongs to rule_manifest_entries_resolve alone, so that
# one broken manifest produces one violation rather than four.
manifest_entries() {
  [ -f "$MANIFEST" ] || return 0

  sed -n '/"skills"[[:space:]]*:[[:space:]]*\[/,/]/p' "$MANIFEST" |
    sed '1s/.*\[//' |
    grep -oE '"[^"]+"' |
    tr -d '"'
}

# The buckets whose docs trees mirror promoted skills: the ones the manifest
# currently names, plus the two CLAUDE.md defines as promoted.
#
# The manifest alone is not enough. Demote or delete every skill in a bucket
# and that bucket vanishes from the manifest, taking its whole docs tree out of
# the orphan rule below at exactly the moment every page in it became an
# orphan. The two names are the floor, so emptying a bucket makes the rule
# louder rather than silent.
#
# It is still a closed list rather than a walk of docs/*/, which is what keeps
# docs/agents/ out. That directory holds this repo's own setup output (issue
# tracker, triage labels, domain layout), not skill documentation, and a rule
# that walked the docs tree would demand a promoted skill named "domain" and
# report three violations against files working exactly as intended.
promoted_buckets() {
  {
    manifest_entries | sed -n 's|^\./skills/\([^/]*\)/.*|\1|p'
    printf '%s\n' engineering productivity
  } | sort -u
}

# Every promoted skill in the manifest resolves to a directory that exists. The
# manifest is the source of truth for what ships, so an entry pointing at
# nothing means the plugin ships a skill that is not there: a rename or a
# delete that updated the tree and not the manifest.
rule_manifest_entries_resolve() {
  if [ ! -f "$MANIFEST" ]; then
    violation "$MANIFEST: missing, so the promoted set cannot be determined"
    return
  fi

  local entries
  mapfile -t entries < <(manifest_entries)

  # An empty parse is a violation in its own right rather than a silent pass:
  # zero entries and a manifest this rule cannot read look identical from here,
  # and the second one must never report clean.
  if [ "${#entries[@]}" -eq 0 ]; then
    violation "$MANIFEST: no entries found in the skills array"
    return
  fi

  local entry
  for entry in "${entries[@]}"; do
    # Report rather than skip anything not shaped like a promoted skill path.
    # Skipping would let a malformed entry pass while the zero-entry guard above
    # stayed quiet, which is the one outcome worse than a false alarm: a checker
    # reporting clean having silently examined a subset.
    case "$entry" in
      ./skills/*) ;;
      *)
        violation "$MANIFEST: skills entry \"$entry\" is not a path under ./skills/"
        continue
        ;;
    esac

    if [ ! -d "${entry#./}" ]; then
      violation "$MANIFEST: skills entry \"$entry\" does not resolve to a directory"
    fi
  done
}

# A promoted skill is wired everywhere CLAUDE.md says it must appear: the
# top-level README, its bucket README, and a docs page. Promoting a skill means
# touching four places, and the manifest is the only one of them that fails
# loudly on its own. The other three fail as an absence, which is exactly the
# kind of thing nobody notices until a reader hits a skill the docs never
# mention.
rule_promoted_skills_are_wired() {
  local entries
  mapfile -t entries < <(manifest_entries)
  [ "${#entries[@]}" -gt 0 ] || return 0

  if [ ! -f README.md ]; then
    violation "README.md: missing, so no promoted skill is listed at the top level"
  fi

  local entry bucket name rel
  for entry in "${entries[@]}"; do
    case "$entry" in
      ./skills/*/*) ;;
      *) continue ;;  # shape is rule_manifest_entries_resolve's to report
    esac

    rel="${entry#./}"
    name="${rel##*/}"
    bucket="${rel%/*}"
    bucket="${bucket##*/}"

    # A directory is not a skill until it has a SKILL.md. The manifest rule
    # stops at the directory, which left this checker passing trees that
    # scripts/link-skills.sh rejects. Same threshold now, so whatever satisfies
    # the checker also links.
    #
    # Only when the directory is there. A skill deleted without updating the
    # manifest is one mistake, and reporting it once as a missing directory says
    # more than reporting it again here as a missing file inside a directory
    # that is also missing.
    if [ -d "$rel" ] && [ ! -f "$rel/SKILL.md" ]; then
      violation "$rel: promoted, but has no SKILL.md"
    fi

    # Link targets, not bare names: CLAUDE.md requires the skill name to link to
    # its SKILL.md, so matching the link is what actually checks the rule. A
    # name mentioned in prose but never linked would satisfy a looser grep.
    if [ ! -f README.md ]; then
      : # reported once below rather than once per promoted skill
    elif ! grep -qF "](./skills/$bucket/$name/SKILL.md)" README.md; then
      violation "README.md: no entry linking $bucket/$name to its SKILL.md"
    fi

    local bucket_readme="skills/$bucket/README.md"
    if [ ! -f "$bucket_readme" ]; then
      violation "$bucket_readme: missing, so $name cannot be listed in its bucket"
    elif ! grep -qF "](./$name/SKILL.md)" "$bucket_readme"; then
      violation "$bucket_readme: no entry linking $name to its SKILL.md"
    fi

    if [ ! -f "docs/$bucket/$name.md" ]; then
      violation "docs/$bucket/$name.md: missing, but $name is promoted"
    fi
  done
}

# No docs page outlives the skill it documents. The docs tree mirrors the
# promoted buckets, so a page with no promoted skill behind it is either a
# skill that was demoted or deleted without taking its page, or a page written
# for a skill that never shipped. Both read to a visitor as documentation for
# something that does not exist.
rule_no_orphaned_docs_pages() {
  local promoted
  mapfile -t promoted < <(manifest_entries)
  [ "${#promoted[@]}" -gt 0 ] || return 0

  local buckets
  mapfile -t buckets < <(promoted_buckets)

  local bucket page name expected found
  for bucket in "${buckets[@]}"; do
    [ -d "docs/$bucket" ] || continue

    for page in "docs/$bucket"/*.md; do
      [ -f "$page" ] || continue
      name="${page##*/}"
      name="${name%.md}"
      expected="./skills/$bucket/$name"

      found=""
      local entry
      for entry in "${promoted[@]}"; do
        if [ "$entry" = "$expected" ]; then
          found=1
          break
        fi
      done

      if [ -z "$found" ]; then
        violation "$page: documents $name, which is not a promoted skill"
      fi
    done
  done
}

# Manifest correctness is delegated, not reimplemented. Claude Code ships the
# authoritative validator for its own plugin format and it moves with the
# format; a hand-rolled copy here would drift and would be wrong in the
# direction that matters, passing something Claude rejects.
#
# It validates the marketplace manifest only. Given the repo root, the CLI
# prints "Validating marketplace manifest" and reads .claude-plugin/
# marketplace.json alone; the plugin manifest needs its own invocation,
# `claude plugin validate .claude-plugin/plugin.json --strict`, which is not
# run here. That invocation currently warns that CLAUDE.md at the plugin root
# is not loaded as project context, which is true and intended, so adding it
# as a rule means deciding what to do with that warning first. CLAUDE.md
# states both invocations and what each covers.
#
# A missing CLI is a skip, not a violation. An unreadable manifest is this
# repo being wrong; an absent CLI is the machine lacking a tool, and the two
# deserve different answers. The repo documents a skills.sh route for Codex and
# other harnesses, so a contributor can reasonably not have Claude Code
# installed, and failing their run over it would be a red they cannot clear.
# The skip is printed every time, and CHECK_REQUIRE_ALL=1 makes it fail.
rule_plugin_manifest_validates() {
  if ! command -v claude >/dev/null 2>&1; then
    skip "marketplace manifest unvalidated: claude CLI not found"
    return
  fi

  # One violation carrying the validator's whole report, rather than one per
  # line of it. A line of someone else's output is not a violation of this
  # repo's invariants, and counting it as one makes the summary lie: a single
  # rejected manifest would read as five or six problems to go and fix.
  local output
  if ! output="$(claude plugin validate . --strict 2>&1)"; then
    violation "claude plugin validate . --strict failed:
$(printf '%s\n' "$output" | sed 's/^/    /')"
  fi
}

RULES=(
  rule_manifest_entries_resolve
  rule_promoted_skills_are_wired
  rule_no_orphaned_docs_pages
  rule_plugin_manifest_validates
)

# A rule that fails outright is reported as a violation rather than allowed to
# abort the run. Without this, `set -e` would kill the whole checker the moment
# any rule ended on a falsy command, and the promise above (every rule runs,
# every violation reported) would hold only for rules careful enough not to.
# That promise has to be the harness's job, not each future rule author's.
#
# The trade-off, and the reason rules must check their own commands: calling a
# rule on the left of `||` suppresses errexit inside it, so a command that fails
# midway through a rule no longer aborts that rule. Preserving errexit per rule
# means running each in its own shell and passing violations back over a pipe,
# which is a real option if the rules ever get complicated enough to want it.
# Today the harness guarantee is the one worth having: one broken rule can never
# silence the others.
for rule in "${RULES[@]}"; do
  "$rule" || violation "$rule: rule failed to complete (exit $?)"
done

if [ "${#skips[@]}" -gt 0 ]; then
  printf 'skipped: %s\n' "${skips[@]}" >&2
fi

if [ "${#violations[@]}" -gt 0 ]; then
  printf '%s\n' "${violations[@]}" >&2
  printf '\n%s violation(s) found by %s rule(s).\n' "${#violations[@]}" "${#RULES[@]}" >&2
  exit 1
fi

if [ "${#skips[@]}" -gt 0 ]; then
  printf 'ok: %s rule(s) passed, %s skipped.\n' "$(( ${#RULES[@]} - ${#skips[@]} ))" "${#skips[@]}"
else
  printf 'ok: %s rule(s) passed.\n' "${#RULES[@]}"
fi
