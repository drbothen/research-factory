#!/usr/bin/env bash
# factory-config.sh — the engine's config loader (§5).
#
# Reads a per-instance `factory.config.yaml` and exposes its fields. The engine
# contains ZERO market logic; everything market-specific (vectors, tracks,
# editorial profile, seed paths) is read from this file (P10).
#
# Usage:
#   factory-config.sh path                 # print the resolved config path
#   factory-config.sh validate [cfg]       # check required fields; exit !=0 on failure
#   factory-config.sh get <yq-expr> [cfg]  # evaluate a yq expression (e.g. '.market')
#   factory-config.sh vectors [cfg]        # <id>\t<name> per evidence vector
#   factory-config.sh tracks  [cfg]        # <slug>\t<name>\t<sourcing> per track
#   factory-config.sh editorial [cfg]      # dump the editorial profile as JSON
#
# Config resolution order: explicit arg → $FACTORY_CONFIG → nearest
# factory.config.yaml walking up from $PWD.
#
# Dependency: yq (mikefarah v4). Deterministic, no LLM.

set -euo pipefail

die() { echo "factory-config.sh: $*" >&2; exit 1; }

command -v yq >/dev/null 2>&1 || die "yq (mikefarah v4) is required but not found"

# --- resolve the config file ---
resolve_config() {
  local explicit="${1:-}"
  if [ -n "$explicit" ]; then
    [ -f "$explicit" ] || die "config not found: $explicit"
    printf '%s\n' "$explicit"; return
  fi
  if [ -n "${FACTORY_CONFIG:-}" ]; then
    [ -f "$FACTORY_CONFIG" ] || die "FACTORY_CONFIG points at a missing file: $FACTORY_CONFIG"
    printf '%s\n' "$FACTORY_CONFIG"; return
  fi
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/factory.config.yaml" ]; then printf '%s\n' "$dir/factory.config.yaml"; return; fi
    dir="$(dirname "$dir")"
  done
  die "no factory.config.yaml found (pass a path, set \$FACTORY_CONFIG, or run inside an instance)"
}

CMD="${1:-}"; [ -n "$CMD" ] || die "usage: factory-config.sh {path|validate|get|vectors|tracks|editorial} [...]"
shift || true

case "$CMD" in
  path)
    resolve_config "${1:-}"
    ;;

  get)
    expr="${1:-}"; [ -n "$expr" ] || die "get requires a yq expression, e.g. '.market'"
    cfg="$(resolve_config "${2:-}")"
    yq -r "$expr" "$cfg"
    ;;

  vectors)
    cfg="$(resolve_config "${1:-}")"
    yq -r '.vectors[] | [.id, .name] | @tsv' "$cfg"
    ;;

  tracks)
    cfg="$(resolve_config "${1:-}")"
    yq -r '.tracks[] | [.slug, .name, (.sourcing // "external-only")] | @tsv' "$cfg"
    ;;

  editorial)
    cfg="$(resolve_config "${1:-}")"
    yq -o=json '.editorial // {}' "$cfg"
    ;;

  validate)
    cfg="$(resolve_config "${1:-}")"
    errs=0
    req_scalar() {
      local key="$1" val
      val="$(yq -r "$key // \"\"" "$cfg")"
      if [ -z "$val" ] || [ "$val" = "null" ]; then echo "  MISSING: $key" >&2; errs=$((errs+1)); fi
    }
    req_nonempty_list() {
      local key="$1" n
      n="$(yq -r "($key // []) | length" "$cfg")"
      if [ "${n:-0}" -lt 1 ]; then echo "  EMPTY/MISSING list: $key" >&2; errs=$((errs+1)); fi
    }
    echo "validating $cfg" >&2
    # YAML must parse at all
    yq -e '.' "$cfg" >/dev/null 2>&1 || die "config is not valid YAML: $cfg"
    req_scalar '.market'
    req_scalar '.slug'
    req_scalar '.seed.scope_doc'
    req_scalar '.seed.source_inventory'
    req_nonempty_list '.vectors'
    req_nonempty_list '.tracks'
    # vector entries need id+name; track entries need slug+name
    bad_vec="$(yq -r '[.vectors[] | select((.id // "")=="" or (.name // "")=="")] | length' "$cfg")"
    [ "${bad_vec:-0}" -eq 0 ] || { echo "  $bad_vec vector(s) missing id or name" >&2; errs=$((errs+1)); }
    bad_trk="$(yq -r '[.tracks[]  | select((.slug // "")=="" or (.name // "")=="")] | length' "$cfg")"
    [ "${bad_trk:-0}" -eq 0 ] || { echo "  $bad_trk track(s) missing slug or name" >&2; errs=$((errs+1)); }
    if [ "$errs" -eq 0 ]; then echo "config validation: PASS" >&2; exit 0
    else echo "config validation: FAIL ($errs error(s))" >&2; exit 1; fi
    ;;

  *)
    die "unknown command: $CMD (use path|validate|get|vectors|tracks|editorial)"
    ;;
esac
