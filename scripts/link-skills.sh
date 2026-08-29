#!/usr/bin/env bash
set -euo pipefail

# NOTE: This is a dev-only script, intended for use by maintainers of this repo.
# It is not a supported installer.
#
# Upstream's copy carried the line "Modifications to it, or requests for
# modifications, will not be approved." That rule was addressed to contributors
# to upstream's repo. It is deliberately dropped here: this repo owns and edits
# this script (see issue #3). Recording the removal rather than deleting the
# sentence silently.
#
# Links this repo's promoted skills into the harness skill directories *inside
# this repo*:
#   - .claude/skills: Claude Code
#   - .agents/skills: Codex and other Agent Skills-compatible harnesses
# Both are gitignored. Scoping the links here rather than to $HOME is
# deliberate: this repo edits the skills themselves, so a machine-wide install
# would mean editing a skill silently changes how every other project behaves.
#
# The promoted set is read from .claude-plugin/plugin.json, which is the single
# source of truth for what ships. Skills in the non-promoted buckets (misc/,
# in-progress/, deprecated/) are never linked.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=("$REPO/.claude/skills" "$REPO/.agents/skills")

cd "$REPO"

# Read the promoted skill paths out of the plugin manifest. Deliberately no JSON
# parser: this script must run with nothing installed.
mapfile -t promoted < <(
  grep -oE '"\./skills/[^"]+"' .claude-plugin/plugin.json | tr -d '"' | sed 's|^\./||'
)

if [ "${#promoted[@]}" -eq 0 ]; then
  echo "error: no skills found in .claude-plugin/plugin.json." >&2
  echo "The manifest is the source of truth for the promoted set; check it parses." >&2
  exit 1
fi

# Verify every promoted entry exists before touching any destination, so a bad
# manifest fails cleanly instead of leaving half-linked directories behind.
missing=()
for rel in "${promoted[@]}"; do
  [ -f "$REPO/$rel/SKILL.md" ] || missing+=("$rel")
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "error: the plugin manifest lists skills that do not exist:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  exit 1
fi

for DEST in "${DESTS[@]}"; do
  # $DEST must be the exact path we intend to write to. If it is a symlink
  # pointing anywhere else, the per-skill links land somewhere unintended: the
  # repo's own skills/ tree, or worse the tracked working copy root, where the
  # prune pass below would start deleting tracked files. Whitelist the intended
  # path rather than blacklisting known-bad ones.
  # readlink -f resolves every component, so this also catches a symlinked
  # .claude or .agents, not just a symlinked skills/ leaf. It is empty only when
  # a parent directory is missing, which mkdir -p below handles.
  resolved="$(readlink -f "$DEST" || true)"
  if [ -n "$resolved" ] && [ "$resolved" != "$DEST" ]; then
    echo "error: $DEST resolves to $resolved, not to itself." >&2
    echo "This script only writes to that exact path; linking elsewhere risks" >&2
    echo "writing symlinks into the tracked working copy." >&2
    echo "Remove the symlink and re-run; it will be recreated as a real dir." >&2
    exit 1
  fi

  mkdir -p "$DEST"

  for rel in "${promoted[@]}"; do
    src="$REPO/$rel"
    name="$(basename "$rel")"
    target="$DEST/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -sfn "$src" "$target"
    echo "linked $name -> ${rel}"
  done

  # Prune links for skills no longer in the promoted set (dropped, or demoted to
  # a non-promoted bucket), so the destination mirrors the manifest exactly.
  for existing in "$DEST"/*; do
    [ -L "$existing" ] || continue
    name="$(basename "$existing")"
    keep=""
    for rel in "${promoted[@]}"; do
      if [ "$(basename "$rel")" = "$name" ]; then
        keep=1
        break
      fi
    done
    if [ -z "$keep" ]; then
      target="$(readlink -f "$existing")"
      case "$target" in
        "$REPO/skills"/*) rm "$existing" ;;
      esac
    fi
  done

  echo "linked ${#promoted[@]} promoted skills into ${DEST#"$REPO"/}"
done

# Clean up after the previous, machine-wide version of this script: anything
# under the home harness paths that points back into this repo.
for OLD in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  [ -d "$OLD" ] || continue
  pruned=0
  for existing in "$OLD"/*; do
    [ -L "$existing" ] || continue
    target="$(readlink -f "$existing")"
    case "$target" in
      "$REPO"|"$REPO"/*) rm "$existing"; pruned=$((pruned + 1)) ;;
    esac
  done
  if [ "$pruned" -gt 0 ]; then
    echo "removed $pruned stale link(s) from $OLD pointing into this repo"
  fi
done
