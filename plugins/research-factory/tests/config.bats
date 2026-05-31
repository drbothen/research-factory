#!/usr/bin/env bats
# Tests for the factory-config.sh loader (§5).

LOADER="${BATS_TEST_DIRNAME}/../bin/factory-config.sh"

setup() {
  TMP="$(mktemp -d)"
  GOOD="$TMP/factory.config.yaml"
  cat > "$GOOD" <<'YAML'
market: "OT/ICS Security"
slug: "ot-ics"
seed:
  scope_doc: "seed/scope.md"
  source_inventory: "seed/sources.md"
  existing_corpus: "corpus/"
vectors:
  - {id: V1, name: "Vendor/competitor"}
  - {id: V2, name: "Operator/user"}
tracks:
  - {slug: competitive-analysis, name: "Competitive Analysis", sourcing: external-only}
  - {slug: regulatory-governance, name: "Regulatory & Governance", sourcing: primary-source}
editorial:
  per_track_sourcing_default: external-only
YAML
}

teardown() { rm -rf "$TMP"; }

@test "validate PASSes a well-formed config" {
  run bash "$LOADER" validate "$GOOD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PASS"* ]]
}

@test "validate FAILs when a required field is missing" {
  bad="$TMP/bad.yaml"
  # drop slug and tracks
  cat > "$bad" <<'YAML'
market: "X"
seed: {scope_doc: "s", source_inventory: "src"}
vectors:
  - {id: V1, name: "Vendor"}
YAML
  run bash "$LOADER" validate "$bad"
  [ "$status" -ne 0 ]
  [[ "$output" == *"FAIL"* ]]
}

@test "get extracts a scalar field" {
  run bash "$LOADER" get '.market' "$GOOD"
  [ "$status" -eq 0 ]
  [ "$output" = "OT/ICS Security" ]
}

@test "vectors lists id and name per vector" {
  run bash "$LOADER" vectors "$GOOD"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == $'V1\tVendor/competitor' ]]
  [ "${#lines[@]}" -eq 2 ]
}

@test "tracks lists slug, name, sourcing" {
  run bash "$LOADER" tracks "$GOOD"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == $'competitive-analysis\tCompetitive Analysis\texternal-only' ]]
  [[ "${lines[1]}" == *$'\tprimary-source' ]]
}

@test "resolves via \$FACTORY_CONFIG when no path is given" {
  FACTORY_CONFIG="$GOOD" run bash "$LOADER" get '.slug'
  [ "$status" -eq 0 ]
  [ "$output" = "ot-ics" ]
}

@test "the shipped template validates" {
  run bash "$LOADER" validate "${BATS_TEST_DIRNAME}/../templates/factory.config.template.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PASS"* ]]
}
