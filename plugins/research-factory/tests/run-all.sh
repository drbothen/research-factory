#!/usr/bin/env bash
# Run all research-factory plugin tests.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v bats &>/dev/null; then
  echo "ERROR: bats not found. Install bats-core (brew install bats-core / apt-get install bats)." >&2
  exit 1
fi
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq not found. Install jq." >&2
  exit 1
fi
if ! command -v yq &>/dev/null; then
  echo "ERROR: yq (mikefarah v4) not found. Install yq." >&2
  exit 1
fi

echo "== research-factory test suite =="
bats "$DIR"/*.bats
