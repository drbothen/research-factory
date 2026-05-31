#!/usr/bin/env bash
# layer-discipline-guard.sh — PreToolUse:Write hook (layer model spine).
#
# Each layer observes ONLY the layer immediately below it. This guard reads a
# corpus doc's frontmatter `layer:` and `layer-observes:` and blocks the write
# if they are inconsistent (L_n must observe L_(n-1)).
#
#   L2→L1  L3→L2  L4→L3  L5→L4  L6→L5
#   L1 observes the external world (layer-observes absent or "external" — allowed).
#
# Guards corpus/*.md only; templates/_meta/seed/index/readme exempt. Deterministic.

set -euo pipefail

command -v jq &>/dev/null || { echo "layer-discipline-guard.sh: jq required" >&2; exit 1; }

INPUT=$(cat)
emit_allow() { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}\n'; exit 0; }
emit_deny() { jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }

FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty')

case "$FILE_PATH" in *"/corpus/"*.md) : ;; *) emit_allow ;; esac
case "$FILE_PATH" in */templates/*|*/_meta/*|*/seed/*) emit_allow ;; esac
case "$(basename "$FILE_PATH")" in README.md|STATE.md|MEMORY.md|*-index.md|index.md) emit_allow ;; esac
[ -z "$CONTENT" ] && emit_allow

# extract frontmatter scalars
fm() { printf '%s' "$CONTENT" | awk -v key="$1" '
  NR==1 && $0=="---"{fm=1;next} fm==1 && $0=="---"{exit}
  fm==1 && $0 ~ "^"key":" { sub("^"key":[[:space:]]*",""); gsub(/["'"'"']/,""); print; exit }'; }

LAYER=$(fm "layer")
OBSERVES=$(fm "layer-observes")

# no layer tag → not our concern here (require-citation/other guards still apply)
[ -z "$LAYER" ] && emit_allow

# normalize to integer (L3 → 3)
ln="${LAYER#L}"; on="${OBSERVES#L}"
case "$ln" in (*[!0-9]*|"") emit_allow ;; esac   # non-standard layer label → skip

if [ "$ln" -le 1 ]; then
  # L1 observes the external world; layer-observes should be empty/external/L0
  case "$OBSERVES" in ""|external|External|L0) emit_allow ;; esac
  emit_deny "Layer discipline: an L1 doc observes the external world; 'layer-observes: $OBSERVES' is invalid. Use 'external' or omit it. ($FILE_PATH)"
fi

# L_n (n>=2) must observe L_(n-1)
expected=$((ln - 1))
if [ -z "$OBSERVES" ]; then
  emit_deny "Layer discipline: $LAYER doc is missing 'layer-observes:'. An $LAYER doc must declare 'layer-observes: L$expected'. ($FILE_PATH)"
fi
case "$on" in (*[!0-9]*|"") emit_deny "Layer discipline: 'layer-observes: $OBSERVES' is not a valid layer. $LAYER must observe L$expected. ($FILE_PATH)" ;; esac
if [ "$on" -ne "$expected" ]; then
  emit_deny "Layer discipline violation: $LAYER must observe L$expected (the layer immediately below), but declares 'layer-observes: $OBSERVES'. Each layer observes only the layer directly beneath it. ($FILE_PATH)"
fi
emit_allow
