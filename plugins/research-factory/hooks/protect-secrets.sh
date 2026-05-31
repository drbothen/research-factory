#!/usr/bin/env bash
# protect-secrets.sh — PreToolUse:Write hook. Blocks writing a credential into
# ANY file. Credentials live in GitHub Secrets / OIDC only (BUILD-PLAN §17).
#
# Matches high-precision secret patterns (provider key prefixes, private keys,
# GitHub tokens, AWS access keys). Deterministic, <100ms.

set -euo pipefail

command -v jq &>/dev/null || { echo "protect-secrets.sh: jq required" >&2; exit 1; }

INPUT=$(cat)
emit_allow() { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}\n'; exit 0; }
emit_deny() { jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }

CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty')
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$CONTENT" ] && emit_allow

# High-precision secret signatures. Each is rarely a false positive.
PATTERNS='(sk-[A-Za-z0-9]{20,})|(pplx-[A-Za-z0-9]{20,})|(tvly-(prod|dev)?-?[A-Za-z0-9]{16,})|(gh[pousr]_[A-Za-z0-9]{30,})|(AKIA[0-9A-Z]{16})|(-----BEGIN [A-Z ]*PRIVATE KEY-----)|(xox[baprs]-[A-Za-z0-9-]{10,})'

if printf '%s' "$CONTENT" | grep -qE "$PATTERNS"; then
  emit_deny "Refusing to write a credential to a file. A secret-shaped token was detected in the content. Credentials must live in GitHub Secrets / OIDC only, never in-repo (BUILD-PLAN §17). Remove the secret or reference it via an env var. ($FILE_PATH)"
fi
emit_allow
