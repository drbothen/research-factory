#!/usr/bin/env bash
# require-citation.sh — PreToolUse:Write hook (Iron Law P3/P4).
#
# Blocks writing a CORPUS CLAIM document that carries substantive claims but
# NO source marker AND NO explicit unsourced-flag. Enforces "no claim ships
# without either a citation or an explicit flag" (anchor-not-strip, P4).
#
# Guards only instance corpus docs: a path containing `/corpus/` ending in `.md`.
# Templates, _meta, seed, and index/state files are exempt. Non-corpus writes
# are allowed immediately.
#
# A document is ALLOWED when ANY of these hold:
#   - it is not a guarded corpus doc
#   - it has fewer than MIN_CLAIM_LINES substantive prose lines (stub/scaffold)
#   - its content contains a citation  (https?://, markdown link to a URL, [^footnote])
#   - its content contains an explicit unsourced flag
#     ([Source needed, [Access required, [unsourced, [citation needed)
#   - its frontmatter declares citation fields (cites:/source:/sources:)
#
# Deterministic, no LLM, <100ms. Emits the PreToolUse JSON envelope.

set -euo pipefail

MIN_CLAIM_LINES="${REQUIRE_CITATION_MIN_LINES:-3}"

if ! command -v jq &>/dev/null; then
  echo "require-citation.sh: jq is required but not found" >&2
  exit 1
fi

INPUT=$(cat)

emit_allow() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}\n'
  exit 0
}

emit_deny() {
  local reason="$1"
  jq -nc --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty')

# --- scope: only guard corpus claim documents ---
case "$FILE_PATH" in
  *"/corpus/"*.md) : ;;            # guarded
  *)               emit_allow ;;   # not a corpus doc
esac

# Exempt structural / non-claim files even inside corpus/
case "$FILE_PATH" in
  */templates/*|*/_meta/*|*/seed/*) emit_allow ;;
esac
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  README.md|STATE.md|MEMORY.md|*-index.md|index.md) emit_allow ;;
esac

# Empty write → allow (creating placeholder)
[ -z "$CONTENT" ] && emit_allow

# --- strip YAML frontmatter to isolate the body ---
BODY=$(printf '%s' "$CONTENT" | awk '
  NR==1 && $0=="---" { fm=1; next }
  fm==1 && $0=="---" { fm=0; next }
  fm==1 { next }
  { print }
')

# Count substantive prose lines: non-empty, not a heading, not a pure
# table/rule/list delimiter, not a blockquote-only line.
CLAIM_LINES=$(printf '%s\n' "$BODY" | grep -vE '^[[:space:]]*$' \
  | grep -vE '^[[:space:]]*#' \
  | grep -vE '^[[:space:]]*([-*+|>]+[[:space:]]*)+$' \
  | grep -vE '^[[:space:]]*[-=|]{3,}[[:space:]]*$' \
  | wc -l | tr -d '[:space:]')

# Below the threshold → treat as scaffold/stub, allow.
if [ "${CLAIM_LINES:-0}" -lt "$MIN_CLAIM_LINES" ]; then
  emit_allow
fi

# --- look for a citation OR an explicit unsourced flag (case-insensitive) ---
# Accepted markers:
#   external  : https?://  · footnote [^…]
#   internal  : [[wikilink]] · a corpus doc reference (…​.md) — synthesis layers (L3/L4/L5)
#               cite DOWNWARD by named lower-layer doc, not by external URL
#   flags     : [Source needed] · [Citation needed] · [Access required] · [unsourced]
#   frontmatter: cites:/source:/sources:
if printf '%s' "$CONTENT" | grep -qiE 'https?://|\[\^|\[\[|[a-z0-9_-]+\.md|\[source needed|\[citation needed|\[access required|\[unsourced|^[[:space:]]*(cites|source|sources):'; then
  emit_allow
fi

emit_deny "Corpus claim document has substantive content but no source marker and no explicit unsourced flag. Every claim must be either cited (a source URL/footnote) or anchored with an explicit flag ([Source needed: ...] / [Access required: ...]) per the anchor-not-strip rule. Add a citation or flag the claim before writing: ${FILE_PATH}"
