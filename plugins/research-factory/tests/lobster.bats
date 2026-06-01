#!/usr/bin/env bats
# Tests for bin/lobster-parse (the .lobster workflow parser, §9).

PARSE="${BATS_TEST_DIRNAME}/../bin/lobster-parse"
WF="${BATS_TEST_DIRNAME}/../workflows"

setup() { TMP="$(mktemp -d)"; }
teardown() { rm -rf "$TMP"; }

@test "every shipped workflow validates" {
  shopt -s nullglob
  local found=0
  for f in "$WF"/*.lobster; do
    found=$((found+1))
    run python3 "$PARSE" validate "$f"
    [ "$status" -eq 0 ] || { echo "FAILED: $f -> $output"; return 1; }
    [[ "$output" == *"PASS"* ]]
  done
  # guard against an empty glob silently passing
  [ "$found" -ge 7 ] || { echo "expected >= 7 workflows, found $found"; return 1; }
}

@test "portfolio-synth (L6) is human-gated and ends at the state-manager commit" {
  run python3 "$PARSE" order "$WF/portfolio-synth.lobster"
  [ "$status" -eq 0 ]
  # the cross-market judgment layer must pass through human-approval before commit, and commit is last
  [[ "$output" == *"human-approval"* ]]
  [ "${lines[${#lines[@]}-1]}" = "commit" ]
}

@test "order is topological (a dependency precedes its dependent)" {
  run python3 "$PARSE" order "$WF/build-track.lobster"
  [ "$status" -eq 0 ]
  # draft must come before synthesize; commit must be last
  draft=-1; synth=-1; i=0
  for line in $output; do
    [ "$line" = "draft" ] && draft=$i
    [ "$line" = "synthesize" ] && synth=$i
    i=$((i+1))
  done
  [ "$draft" -lt "$synth" ]
  [ "${lines[${#lines[@]}-1]}" = "commit" ]
}

@test "detects a dependency cycle" {
  cat > "$TMP/cyc.lobster" <<'YAML'
name: cyclic
steps:
  - {name: a, type: gate, depends_on: [b]}
  - {name: b, type: gate, depends_on: [a]}
YAML
  run python3 "$PARSE" validate "$TMP/cyc.lobster"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cycle"* ]]
}

@test "rejects depends_on referencing an unknown step" {
  cat > "$TMP/dangling.lobster" <<'YAML'
name: dangling
steps:
  - {name: a, type: gate, depends_on: [nonexistent]}
YAML
  run python3 "$PARSE" validate "$TMP/dangling.lobster"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown step"* ]]
}

@test "rejects an invalid step type" {
  cat > "$TMP/badtype.lobster" <<'YAML'
name: badtype
steps:
  - {name: a, type: frobnicate}
YAML
  run python3 "$PARSE" validate "$TMP/badtype.lobster"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not in"* ]]
}

@test "agent step missing its agent field is rejected" {
  cat > "$TMP/noagent.lobster" <<'YAML'
name: noagent
steps:
  - {name: a, type: agent}
YAML
  run python3 "$PARSE" validate "$TMP/noagent.lobster"
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires field 'agent'"* ]]
}

@test "empty steps list is rejected" {
  cat > "$TMP/empty.lobster" <<'YAML'
name: empty
steps: []
YAML
  run python3 "$PARSE" validate "$TMP/empty.lobster"
  [ "$status" -ne 0 ]
  [[ "$output" == *"non-empty list"* ]]
}
