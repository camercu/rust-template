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
  # Template-only files must not ship (the [template] ignore list).
  leaked=0
  for f in scripts/test-template.sh .github/workflows/template.yml; do
    if [ -e "$scratch/$name/$f" ]; then
      echo "FAIL $kind: template-only $f shipped"
      leaked=1
    fi
  done
  [ "$leaked" = 0 ] && echo "ok   $kind: template-only files not shipped"
  fails=$((fails + leaked))

  if (cd "$scratch/$name" && nix-shell --run 'just setup && just ci') >"$scratch/$kind.log" 2>&1; then
    echo "ok   $kind: just ci"
  else
    echo "FAIL $kind: just ci (last lines below)"
    tail -n 5 "$scratch/$kind.log"
    fails=$((fails + 1))
  fi

  # Git hooks export GIT_DIR. cargo-deny (lint-deny) updates its advisory db
  # with `git -C <db> fetch` + `reset --hard FETCH_HEAD`, and -C does not
  # override GIT_DIR: inside a hook, that fetched the project's own origin
  # and reset HEAD to it, dropping unpushed commits (seen pushing a
  # submodule). The project here has one commit its origin lacks. Fixture
  # commits skip hooks: `just setup` installed commitlint.
  if (
    set -e
    cd "$scratch/$name"
    git init -q --bare "$scratch/origin-$kind.git"
    git remote add origin "$scratch/origin-$kind.git"
    git add -A && git -c user.name=t -c user.email=t@t -c core.hooksPath=/dev/null commit -q -m generated
    git -c core.hooksPath=/dev/null push -q origin HEAD:main
    git -c user.name=t -c user.email=t@t -c core.hooksPath=/dev/null commit -q --allow-empty -m unpushed
    head=$(git rev-parse HEAD)
    GIT_DIR="$PWD/.git" nix-shell --run 'just lint-deny' >/dev/null 2>&1 || true
    [ "$(git rev-parse HEAD)" = "$head" ]
  ) >>"$scratch/$kind.log" 2>&1; then
    echo "ok   $kind: recipes ignore an inherited GIT_DIR"
  else
    echo "FAIL $kind: lint-deny under a hook's GIT_DIR reset away an unpushed commit"
    fails=$((fails + 1))
  fi
done
[ "$fails" = 0 ]
