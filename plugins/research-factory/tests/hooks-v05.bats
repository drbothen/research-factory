#!/usr/bin/env bats
# Tests for the v0.5 fail-closed hooks: layer-discipline, protect-secrets, forbidden-phrase.

HDIR="${BATS_TEST_DIRNAME}/../hooks"
payload() { jq -nc --arg fp "$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}'; }

# ---- layer-discipline-guard ----
@test "layer-discipline: allows L3 observing L2" {
  body=$'---\nlayer: L3\nlayer-observes: L2\n---\n# Findings\n'
  run bash "$HDIR/layer-discipline-guard.sh" <<< "$(payload /x/corpus/t/foo.md "$body")"
  [ "$status" -eq 0 ]; [[ "$output" == *'"allow"'* ]]
}

@test "layer-discipline: DENIES L4 that declares it observes L2 (skipping L3)" {
  body=$'---\nlayer: L4\nlayer-observes: L2\n---\n# Synthesis\n'
  run bash "$HDIR/layer-discipline-guard.sh" <<< "$(payload /x/corpus/t/foo.md "$body")"
  [ "$status" -eq 0 ]; [[ "$output" == *'"deny"'* ]]
}

@test "layer-discipline: DENIES L3 missing layer-observes" {
  body=$'---\nlayer: L3\n---\n# Findings\n'
  run bash "$HDIR/layer-discipline-guard.sh" <<< "$(payload /x/corpus/t/foo.md "$body")"
  [ "$status" -eq 0 ]; [[ "$output" == *'"deny"'* ]]
}

@test "layer-discipline: allows L1 observing external" {
  body=$'---\nlayer: L1\nlayer-observes: external\n---\n# Source capture\n'
  run bash "$HDIR/layer-discipline-guard.sh" <<< "$(payload /x/corpus/t/foo.md "$body")"
  [ "$status" -eq 0 ]; [[ "$output" == *'"allow"'* ]]
}

@test "layer-discipline: allows non-corpus path" {
  run bash "$HDIR/layer-discipline-guard.sh" <<< "$(payload /x/notes/foo.md $'---\nlayer: L4\nlayer-observes: L1\n---\nx')"
  [ "$status" -eq 0 ]; [[ "$output" == *'"allow"'* ]]
}

# ---- protect-secrets ----
@test "protect-secrets: DENIES writing a pplx key" {
  run bash "$HDIR/protect-secrets.sh" <<< "$(payload /x/any/config.md $'key: pplx-FAKE0000000000000000000000EXAMPLE')"
  [ "$status" -eq 0 ]; [[ "$output" == *'"deny"'* ]]
}

@test "protect-secrets: DENIES writing a private key block" {
  run bash "$HDIR/protect-secrets.sh" <<< "$(payload /x/any/id.pem $'-----BEGIN OPENSSH PRIVATE KEY-----\nabc\n-----END-----')"
  [ "$status" -eq 0 ]; [[ "$output" == *'"deny"'* ]]
}

@test "protect-secrets: allows ordinary prose mentioning api keys conceptually" {
  run bash "$HDIR/protect-secrets.sh" <<< "$(payload /x/any/doc.md $'The vendor rotates its API keys quarterly per policy.')"
  [ "$status" -eq 0 ]; [[ "$output" == *'"allow"'* ]]
}

# ---- forbidden-phrase-guard ----
@test "forbidden-phrase: DENIES company positioning in a corpus doc" {
  body=$'# Note\n\nGiven the gap, 1898 should build a consequence-reduction product.\n'
  run bash "$HDIR/forbidden-phrase-guard.sh" <<< "$(payload /x/corpus/t/foo.md "$body")"
  [ "$status" -eq 0 ]; [[ "$output" == *'"deny"'* ]]
}

@test "forbidden-phrase: allows sourced observation without positioning" {
  body=$'# Note\n\nWalsh describes translation as the binding constraint ([talk](https://x.com)).\n'
  run bash "$HDIR/forbidden-phrase-guard.sh" <<< "$(payload /x/corpus/t/foo.md "$body")"
  [ "$status" -eq 0 ]; [[ "$output" == *'"allow"'* ]]
}

@test "forbidden-phrase: allows positioning language outside the corpus (e.g. plan docs)" {
  run bash "$HDIR/forbidden-phrase-guard.sh" <<< "$(payload /x/docs/plan.md $'We should build the engine first.')"
  [ "$status" -eq 0 ]; [[ "$output" == *'"allow"'* ]]
}
