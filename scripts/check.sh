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
# Two invocations, because neither covers both manifests.
#
# The ticket that asked for this said the first command "reads
# marketplace.json only" and never opens plugin.json. That turns out to be
# wrong, and the test that showed it is worth recording: delete the name field
# from plugin.json and the marketplace run reports
# "plugins[0] plugin.json -> name: Invalid input", so it does validate the
# plugin manifest's fields through the marketplace's plugin list.
#
# The second invocation still earns its place, because the two are not
# redundant: the plugin-manifest run also checks the plugin root, which is
# where the CLAUDE.md warning below comes from, and the marketplace run never
# emits it. Validating the file directly is also what keeps plugin.json covered
# if it ever stops being reachable from marketplace.json.
#
# The plugin-manifest run always warns that CLAUDE.md at the plugin root is not
# loaded as project context, and --strict promotes that to a failure. The
# warning is accurate and permanently inapplicable: the validator's suggested
# remedy is to ship the context as a skill, but CLAUDE.md is instructions for
# people working on this repository and is deliberately not shipped to plugin
# consumers. So it is filtered out and anything else still fails.
#
# The filter matches the warning's text, so a reworded message in a future
# Claude Code release stops matching and fails this rule. That is the direction
# to fail in: a new failure gets read, a silent pass does not. Same ordering as
# the zero-entry guard in rule_manifest_entries_resolve.
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

  # Reported separately from the marketplace run above. They validate different
  # files, so collapsing them would leave the reader working out which manifest
  # the output belongs to.
  # U+276F, the glyph the validator prefixes each finding with. Spelt as bytes
  # for the same reason the em dash is: so the character itself stays out of
  # this file's prose.
  local findings_bullet=$'\xe2\x9d\xaf'

  local plugin_output filtered
  if ! plugin_output="$(claude plugin validate .claude-plugin/plugin.json --strict 2>&1)"; then
    # The validator prints each finding as its own bulleted line and everything
    # else as chrome: what it is validating, how many findings there were, and
    # the verdict. So drop the one finding that is permanently inapplicable
    # here, then ask whether any finding is left. Matching on the bullet rather
    # than on the chrome means a new warning is caught whatever its wording,
    # and only the exact known line is ever suppressed.
    filtered="$(printf '%s\n' "$plugin_output" |
      grep "$findings_bullet" |
      grep -v 'CLAUDE.md at the plugin root is not loaded as project context' || true)"

    if [ -n "$filtered" ]; then
      violation "claude plugin validate .claude-plugin/plugin.json --strict failed:
$(printf '%s\n' "$filtered" | sed 's/^/    /')"
    fi
  fi
}

# Every tracked file, NUL separated, symlinks excluded.
#
# git rather than find: find would walk .git/ and any untracked scratch file in
# the tree, and neither is this repo making a claim. A clone has git by
# definition, so this is not the kind of dependency the header rules out, but a
# tarball download is not a clone, hence the guard in the two rules below.
#
# AGENTS.md is a symlink to CLAUDE.md. Following it would count the same bytes
# twice and make every allowance below need a second, identical entry that says
# nothing.
#
# NUL separated in and out, because a path is not a line. `git ls-files -s -z`
# emits "<mode> <object> <stage>\t<path>" with the path verbatim and NUL
# terminated, so cutting at the first tab is exact: no quoting to undo, and a
# name containing a space, a doubled space, or a newline survives it. Callers
# read it back with `read -r -d ''` for the same reason.
tracked_text_files() {
  local entry
  while IFS= read -r -d '' entry; do
    case "$entry" in
      120000\ *) continue ;;
    esac
    printf '%s\0' "${entry#*$'\t'}"
  done < <(git ls-files -s -z)
}

# The strings that name upstream, and the exact number of times each is allowed
# to appear in each file that is allowed to carry it.
#
# A count rather than a bare path, because a path alone is a blanket exemption:
# it would let a new reference slip into README.md unnoticed precisely because
# README.md is a file where one reference belongs. Pinning the number means the
# allowance covers the sentence that earned it and nothing else.
#
# The cost is that rewording an allowed sentence fails this rule until the
# number is updated. That is the direction to fail in, and it is a one-line
# fix: the alternative is a leak that reports clean because it landed in a file
# already on the list.
#
# Each entry is "<count> <path>". Every file not named here must contain none.
upstream_identity_allowances() {
  cat <<'ALLOW'
1 LICENSE
2 README.md
2 UPSTREAM.md
1 CLAUDE.md
1 CONTEXT.md
3 docs/agents/issue-tracker.md
11 .agents/adr/0002-ship-as-a-claude-code-plugin.md
1 .agents/adr/0004-drop-the-router-rather-than-rename-it.md
6 scripts/check.sh
ALLOW
}

# Why each allowance exists, so that removing one is a decision rather than a
# guess:
#
#   LICENSE                     upstream's copyright line, the MIT obligation
#   README.md                   the one derivation sentence (link text + URL)
#   UPSTREAM.md                 the seed statement, same shape
#   CLAUDE.md                   the rule that this repo was seeded, not forked
#   CONTEXT.md                  the glossary entry defining Upstream
#   docs/agents/issue-tracker.md  the two-remote note that stops a write to
#                               upstream; deleting it is a safety regression
#   adr/0002                    inherited reasoning, which CLAUDE.md says to
#                               annotate rather than edit
#   adr/0004                    records why ask-matt was dropped; the decision
#                               is unreadable without naming what was dropped
#   scripts/check.sh            this rule's own pattern, plus the note above
#                               that names what it is about. The five patterns
#                               and that one mention are the six; changing
#                               either fails this rule until the count is
#                               re-counted, which is the point.
rule_no_upstream_identity() {
  if ! command -v git >/dev/null 2>&1 || ! git rev-parse --git-dir >/dev/null 2>&1; then
    skip "upstream identity strings unchecked: not a git working tree"
    return
  fi

  local pattern='mattpocock|matt pocock|ask-matt|aihero|ai-hero'

  local allowed_paths=() allowed_counts=() count path
  while read -r count path; do
    [ -n "$path" ] || continue
    allowed_paths+=("$path")
    allowed_counts+=("$count")
  done < <(upstream_identity_allowances)

  # Counted per file rather than per line: two references on one line are two
  # references, and a rule that could not tell them apart would let a second one
  # in wherever a first was allowed.
  local found_paths=() found_counts=() file n i
  while IFS= read -r -d '' file; do
    [ -f "$file" ] || continue
    n="$(grep -oIiE "$pattern" "$file" 2>/dev/null | grep -c . || true)"
    if [ "$n" -gt 0 ]; then
      found_paths+=("$file")
      found_counts+=("$n")
    fi
  done < <(tracked_text_files)

  local j matched expected
  for i in "${!found_paths[@]}"; do
    matched=""
    for j in "${!allowed_paths[@]}"; do
      if [ "${allowed_paths[$j]}" = "${found_paths[$i]}" ]; then
        matched=1
        expected="${allowed_counts[$j]}"
        break
      fi
    done

    if [ -z "$matched" ]; then
      violation "${found_paths[$i]}: ${found_counts[$i]} upstream identity string(s), in a file with no allowance"
    elif [ "${found_counts[$i]}" != "$expected" ]; then
      violation "${found_paths[$i]}: ${found_counts[$i]} upstream identity string(s), but the allowance is $expected"
    fi
  done

  # A stale allowance is reported too. Left unchecked the list would only ever
  # grow, and an allowance outliving the sentence it was written for is how the
  # narrow list quietly becomes the blanket exemption it exists to avoid.
  for j in "${!allowed_paths[@]}"; do
    matched=""
    for i in "${!found_paths[@]}"; do
      if [ "${found_paths[$i]}" = "${allowed_paths[$j]}" ]; then
        matched=1
        break
      fi
    done
    [ -n "$matched" ] || violation "${allowed_paths[$j]}: allowed ${allowed_counts[$j]} upstream identity string(s) but carries none, so the allowance is stale"
  done
}

# No em dash anywhere. CLAUDE.md states the rule for this repo's prose and lists
# where prose lives: SKILL.md files, docs, README.md, ADRs, code comments. That
# list is nearly every text file here, so the rule reads all of them rather than
# maintaining a second copy of the list that would drift from the first.
#
# It reports the character, never rewrites it. CLAUDE.md is explicit that the
# fix is a rewrite into whatever the sentence actually wants, a comma, colon,
# period, parentheses or a conjunction, and "never do a blind character
# substitution". A checker that fixed this automatically would be doing exactly
# the substitution the convention forbids.
rule_no_em_dashes() {
  if ! command -v git >/dev/null 2>&1 || ! git rev-parse --git-dir >/dev/null 2>&1; then
    skip "em dashes unchecked: not a git working tree"
    return
  fi

  # Spelt as its UTF-8 bytes, not as the character. Written literally, the rule
  # would match its own source on every run, and the only ways out of that are
  # an exemption for this file or a count pinned to a line of code, both worse
  # than one escape sequence.
  local emdash=$'\xe2\x80\x94'

  local file hits
  while IFS= read -r -d '' file; do
    [ -f "$file" ] || continue
    # -I so a binary file is skipped rather than reported as one long match.
    hits="$(grep -nI -- "$emdash" "$file" 2>/dev/null || true)"
    if [ -n "$hits" ]; then
      while IFS= read -r hit; do
        violation "$file:${hit%%:*}: em dash"
      done <<< "$hits"
    fi
  done < <(tracked_text_files)
}

RULES=(
  rule_manifest_entries_resolve
  rule_promoted_skills_are_wired
  rule_no_orphaned_docs_pages
  rule_plugin_manifest_validates
  rule_no_upstream_identity
  rule_no_em_dashes
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
