#!/usr/bin/env bash
# Generate a project of each crate kind from this working tree and run its
# full `just ci`. Nothing else exercises generated output: a binary project
# failed `just ci` (doc-tests need a lib target) until this existed.
# Kept out of generated projects by the [template] ignore list.
# usage: scripts/test-template.sh [library|binary ...]   (default: both)
set -euo pipefail

template="$(cd "$(dirname "$0")/.." && pwd)"
kinds=("$@")
[ ${#kinds[@]} -gt 0 ] || kinds=(library binary)
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
fails=0

for kind in "${kinds[@]}"; do
  name="tt-$kind"
  (cd "$scratch" && nix-shell -p cargo-generate --run \
    "cargo generate --path '$template' --name $name --silent \
      --define gh_username=test --define 'license=MIT OR Apache-2.0' \
      --define kind=$kind" \
    >/dev/null)
  if (cd "$scratch/$name" && nix-shell --run 'just setup && just ci') >"$scratch/$kind.log" 2>&1; then
    echo "ok   $kind: just ci"
  else
    echo "FAIL $kind: just ci (last lines below)"
    tail -n 5 "$scratch/$kind.log"
    fails=$((fails + 1))
  fi

done
[ "$fails" = 0 ]
