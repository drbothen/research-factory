#!/usr/bin/env bats
# Tests for the require-citation PreToolUse:Write gate (v0.1 acceptance).
# Proves the gate DENIES an uncited corpus claim and ALLOWS cited/flagged/exempt writes.

HOOK="${BATS_TEST_DIRNAME}/../hooks/require-citation.sh"

# Build a PreToolUse Write payload: $1 = file_path, $2 = content
payload() {
  jq -nc --arg fp "$1" --arg c "$2" \
    '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}'
}

@test "denies a corpus claim doc with substantive prose and no source marker" {
  body=$'---\nlayer: L2\n---\n# Finding\n\nThe vendor shipped a new detection engine in 2026.\nIt was deployed across three utilities.\nOperators reported a measurable reduction in dwell time.\n'
  p="$(payload /x/corpus/competitive-analysis/foo.md "$body")"
  run bash "$HOOK" <<< "$p"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"deny"'* ]]
}

@test "allows a corpus claim doc that carries a URL citation" {
  body=$'# Finding\n\nThe vendor shipped a new engine ([source](https://example.com/post)).\nIt was deployed across three utilities.\nDwell time dropped measurably.\n'
  p="$(payload /x/corpus/competitive-analysis/foo.md "$body")"
  run bash "$HOOK" <<< "$p"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}

@test "allows a corpus doc whose claims are explicitly flagged (anchor-not-strip)" {
  body=$'# Finding\n\nThe vendor reportedly shipped a new engine. [Source needed: vendor press release]\nDeployed across utilities. [Access required: broker report — ~$300]\nDwell time fell.\n'
  p="$(payload /x/corpus/competitive-analysis/foo.md "$body")"
  run bash "$HOOK" <<< "$p"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}

@test "allows a non-corpus write with no citation" {
  p="$(payload /x/notes/scratch.md $'Just a scratch note with several\nlines of plain text and\nno citations at all.\n')"
  run bash "$HOOK" <<< "$p"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}

@test "allows a corpus stub below the claim-line threshold" {
  p="$(payload /x/corpus/competitive-analysis/stub.md $'# Title\n\nTODO.\n')"
  run bash "$HOOK" <<< "$p"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}

@test "exempts template paths even with no citation" {
  body=$'# {{title}}\n\nClaim one goes here.\nClaim two goes here.\nClaim three goes here.\n'
  p="$(payload /x/corpus/templates/findings.md "$body")"
  run bash "$HOOK" <<< "$p"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}

@test "allows an L4 synthesis doc that cites L3 sources by internal doc reference" {
  body=$'---\nlayer: L4\nlayer-observes: L3\n---\n# Cross-track synthesis\n\nThree tracks converge on the operationalization gap (ot-security-it-soc-lens-findings-tldr.md).\nThe compliance-to-consequence decoupling appears across four tracks.\nInsurance functions as default governance (ot-security-insurance-risk-transfer-findings-tldr.md).\n'
  p="$(payload /x/corpus/synthesis/foo.md "$body")"
  run bash "$HOOK" <<< "$p"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}

@test "allows a doc that cites via [[wikilink]]" {
  body=$'# Findings\n\nThe boundary is the incident pathway [[ot-security-hearings-findings-tldr]].\nThis holds across multiple tracks.\nThe pattern is consistent.\n'
  p="$(payload /x/corpus/t/foo.md "$body")"
  run bash "$HOOK" <<< "$p"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}

@test "allows when frontmatter declares a sources field" {
  body=$'---\nlayer: L2\nsources:\n  - https://example.com/a\n---\n# Finding\n\nClaim one.\nClaim two.\nClaim three.\n'
  p="$(payload /x/corpus/competitive-analysis/foo.md "$body")"
  run bash "$HOOK" <<< "$p"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}
