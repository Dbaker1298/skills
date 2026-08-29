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
# coreutils has to earn its way back in.
#
# scripts/link-skills.sh parses the same manifest for the same set. Two
# standalone readers is under the rule of three and both scripts are meant to
# run alone, so they stay separate. A third one should become a shared helper
# rather than a third variant.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

violations=()

violation() {
  violations+=("$1")
}

# Every promoted skill in .claude-plugin/plugin.json resolves to a directory
# that exists. The manifest is the source of truth for what ships, so an entry
# pointing at nothing means the plugin ships a skill that is not there: a
# rename or a delete that updated the tree and not the manifest.
rule_manifest_entries_resolve() {
  local manifest=".claude-plugin/plugin.json"

  if [ ! -f "$manifest" ]; then
    violation "$manifest: missing, so the promoted set cannot be determined"
    return
  fi

  # Read the skills array only, rather than every ./skills/ string in the file.
  # A whole-file grep would also match a path quoted in some future description
  # or command field and check it as though it were an entry. The first sed
  # takes the array's lines, the second drops everything up to the opening
  # bracket so the "skills" key itself is not mistaken for an element.
  local array
  array="$(sed -n '/"skills"[[:space:]]*:[[:space:]]*\[/,/]/p' "$manifest" | sed '1s/.*\[//')"

  local entries
  mapfile -t entries < <(printf '%s' "$array" | grep -oE '"[^"]+"' | tr -d '"')

  # An empty parse is a violation in its own right rather than a silent pass:
  # zero entries and a manifest this rule cannot read look identical from here,
  # and the second one must never report clean.
  if [ "${#entries[@]}" -eq 0 ]; then
    violation "$manifest: no entries found in the skills array"
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
        violation "$manifest: skills entry \"$entry\" is not a path under ./skills/"
        continue
        ;;
    esac

    if [ ! -d "${entry#./}" ]; then
      violation "$manifest: skills entry \"$entry\" does not resolve to a directory"
    fi
  done
}

RULES=(
  rule_manifest_entries_resolve
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

if [ "${#violations[@]}" -gt 0 ]; then
  printf '%s\n' "${violations[@]}" >&2
  printf '\n%s violation(s) found by %s rule(s).\n' "${#violations[@]}" "${#RULES[@]}" >&2
  exit 1
fi

printf 'ok: %s rule(s) passed.\n' "${#RULES[@]}"
