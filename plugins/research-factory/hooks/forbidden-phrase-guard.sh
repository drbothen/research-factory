#!/usr/bin/env bash
# forbidden-phrase-guard.sh — PreToolUse:Write hook (observe-and-report integrity).
#
# A bright-line backstop: blocks corpus docs that contain FIRST-PERSON / COMPANY
# positioning or "what we should build" language — phrasing that is never
# legitimate in an observe-only external corpus, regardless of attribution.
#
# This is deliberately NARROW (high precision). The nuanced sweep — superlatives,
# mandate-path, source-attributed judgment — is the editorial-sweeper AGENT's job,
# because it requires reasoning about attribution that a deterministic hook cannot do.
#
# Guards corpus/*.md only; templates/_meta/seed/index/readme exempt.

set -euo pipefail

command -v jq &>/dev/null || { echo "forbidden-phrase-guard.sh: jq required" >&2; exit 1; }

INPUT=$(cat)
emit_allow() { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}\n'; exit 0; }
emit_deny() { jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }

FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty')

case "$FILE_PATH" in *"/corpus/"*.md) : ;; *) emit_allow ;; esac
case "$FILE_PATH" in */templates/*|*/_meta/*|*/seed/*) emit_allow ;; esac
case "$(basename "$FILE_PATH")" in README.md|STATE.md|MEMORY.md|*-index.md|index.md) emit_allow ;; esac
[ -z "$CONTENT" ] && emit_allow

# Bright-line positioning / "what to build" phrases (case-insensitive). Generic patterns only —
# market-specific company names (e.g. "<your company> should build") belong in the instance's
# editorial.forbidden_phrases_extra (P10: no market-specific logic in the generic engine).
FORBIDDEN='(we should build|we recommend building|the product we should build|our recommendation is to build|the moat is|where we should invest|pick a winner|we should prioritize building)'

if printf '%s' "$CONTENT" | grep -qiE "$FORBIDDEN"; then
  hit=$(printf '%s' "$CONTENT" | grep -ioE "$FORBIDDEN" | head -1)
  emit_deny "Observe-and-report violation: corpus doc contains company-positioning / 'what to build' language (\"$hit\"). The corpus is observe-only through L4; 'what the company should build' is out of scope. Reframe as a sourced observation, or move judgment to L5 (which cites L4). ($FILE_PATH)"
fi
emit_allow
