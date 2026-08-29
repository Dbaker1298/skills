#!/usr/bin/env bash
set -euo pipefail

# NOTE: This is a dev-only script, intended for use by maintainers of this repo.
# It is not a supported installer.
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
  # If $DEST resolves back into the repo's own skills/ tree, the per-skill
  # symlinks would be written into the source of truth itself. Bail out rather
  # than pollute the working copy.
  if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    resolved="$(readlink -f "$DEST")"
    case "$resolved" in
      "$REPO/skills"|"$REPO/skills"/*)
        echo "error: $DEST resolves into this repo's own skills tree ($resolved)." >&2
        echo "Linking there would write symlinks into the source of truth." >&2
        echo "Remove it (rm \"$DEST\") and re-run; the script will recreate it as a real dir." >&2
        exit 1
        ;;
    esac
  fi

  mkdir -p "$DEST"

  # Drop links left over from a previous run: a skill that has since been
  # dropped or renamed should stop resolving, not linger.
  for existing in "$DEST"/*; do
    [ -L "$existing" ] || continue
    target="$(readlink -f "$existing" || true)"
    case "$target" in
      "$REPO/skills"/*) [ -f "$target/SKILL.md" ] || rm "$existing" ;;
      *) ;;
    esac
  done

  for rel in "${promoted[@]}"; do
    src="$REPO/$rel"
    name="$(basename "$rel")"
    target="$DEST/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -sfn "$src" "$target"
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
      target="$(readlink -f "$existing" || true)"
      case "$target" in
        "$REPO"/*) rm "$existing" ;;
      esac
    fi
  done

  echo "linked ${#promoted[@]} promoted skills into ${DEST#$REPO/}"
done

# Clean up after the previous, machine-wide version of this script: anything
# under the home harness paths that points back into this repo.
for OLD in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  [ -d "$OLD" ] || continue
  pruned=0
  for existing in "$OLD"/*; do
    [ -L "$existing" ] || continue
    target="$(readlink -f "$existing" || true)"
    case "$target" in
      "$REPO"|"$REPO"/*) rm "$existing"; pruned=$((pruned + 1)) ;;
    esac
  done
  if [ "$pruned" -gt 0 ]; then
    echo "removed $pruned stale link(s) from $OLD pointing into this repo"
  fi
  rmdir "$OLD" 2>/dev/null || true
done
