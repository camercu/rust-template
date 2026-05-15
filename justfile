set shell := ["bash", "-euo", "pipefail", "-c"]

warnings := "-D warnings"
stable_toolchain := "+stable"

default:
    @just --list

# ── Formatting ──────────────────────────────────────────────

fmt: fmt-rust fmt-taplo

fmt-rust:
    cargo fmt --all

# Format every TOML file in the workspace via taplo. Mirrors fmt-rust
# so a single `just fmt` keeps both Rust and TOML aligned.
fmt-taplo:
    taplo format

fmt-check:
    cargo fmt --all --check

# ── Linting ─────────────────────────────────────────────────

lint: fmt-check lint-clippy lint-typos lint-taplo lint-deny

lint-clippy:
    cargo clippy --all-targets --workspace -- {{warnings}}

lint-clippy-stable:
    cargo {{stable_toolchain}} clippy --all-targets --workspace

lint-typos:
    typos

# Check that every TOML file in the workspace is formatted by taplo.
# Runs in `just lint` and `just ci`; surfaces drift before it slips
# into a review.
lint-taplo:
    taplo format --check

lint-deny:
    cargo deny check advisories licenses bans sources

# ── Testing ─────────────────────────────────────────────────

# Two passes because nextest does not yet support doc-tests upstream;
# `cargo test --doc` covers them, `nextest` covers unit + integration
# tests with parallel execution + better output.
test:
    cargo nextest run --workspace
    cargo test --workspace --doc

# Latest-stable sanity check. Skips any `compile_fixtures` test
# (typically a trybuild harness whose `.stderr` snapshots are
# byte-exact against the canonical toolchain pinned in
# `.tool-versions`); rustc diagnostic text drifts between minor
# releases and would otherwise break this advisory job every time
# stable ticks. The canonical-gate job (`just test`) runs every
# test, including the fixtures, on the pinned toolchain.
test-stable:
    cargo {{stable_toolchain}} nextest run --workspace -E 'not test(compile_fixtures)'
    cargo {{stable_toolchain}} test --workspace --doc

# ── Building / checking ─────────────────────────────────────

build:
    cargo build --workspace --all-targets

# ── Documentation ───────────────────────────────────────────

doc:
    RUSTDOCFLAGS="{{warnings}}" cargo doc --workspace --no-deps

# ── Tool versions ───────────────────────────────────────────

check-tool-versions:
    #!/usr/bin/env bash
    set -euo pipefail
    drift=0
    while read -r name version; do
        case "$name" in
            rust)          actual=$(rustc --version | awk '{print $2}') ;;
            just)          actual=$(just --version | awk '{print $2}') ;;
            cargo-deny)    actual=$(cargo-deny --version | awk '{print $2}') ;;
            cargo-nextest) actual=$(cargo nextest --version | head -1 | awk '{print $2}') ;;
            typos-cli)     actual=$(typos --version | awk '{print $2}') ;;
            taplo-cli)     actual=$(taplo --version | awk '{print $2}') ;;
            nodejs)        actual=$(node --version | sed 's/^v//') ;;
            *)
                # Loud failure: a new entry in `.tool-versions` without
                # a matching case here would otherwise drift silently.
                printf '  %-14s unrecognized (add a case to check-tool-versions)\n' "$name"
                drift=1
                continue
                ;;
        esac
        if [ "$actual" != "$version" ]; then
            printf '  %-14s pinned=%s  actual=%s\n' "$name" "$version" "$actual"
            drift=1
        fi
    done < <(grep -v '^#' .tool-versions | grep -v '^$')
    # `rust-toolchain.toml` is read by rustup when devs `cd` into the
    # repo, so its `channel` must agree with `.tool-versions`' rust
    # line — otherwise local builds and CI use different toolchains.
    if [ -f rust-toolchain.toml ]; then
        rt_channel=$(grep -E '^channel\s*=' rust-toolchain.toml | head -1 | sed -E 's/^channel\s*=\s*"([^"]+)".*/\1/')
        tv_rust=$(grep -E '^rust\s' .tool-versions | awk '{print $2}')
        if [ -n "$rt_channel" ] && [ "$rt_channel" != "$tv_rust" ]; then
            printf '  %-14s .tool-versions=%s  rust-toolchain.toml=%s\n' \
                'rust (channel)' "$tv_rust" "$rt_channel"
            drift=1
        fi
    fi
    if [ "$drift" -eq 1 ]; then
        echo "tool versions have drifted from .tool-versions"
        exit 1
    else
        echo "all tool versions match .tool-versions"
    fi

# ── Setup ───────────────────────────────────────────────────

setup:
    ./scripts/setup-dev.sh

# ── Hooks ───────────────────────────────────────────────────

# Fast checks run on every git commit via pre-commit. Mirrors the
# fast tier of `just lint` (fmt + typos + taplo); the heavier checks
# (clippy, deny, tests) live in `just pre-push`.
pre-commit: fmt-check lint-typos lint-taplo
    cargo check --all-targets --workspace --quiet

# Slower checks run on every git push via pre-commit. Mirrors `just
# ci` so anything red in CI was already red locally; the gap that
# previously skipped lint-taplo allowed taplo drift to land on main.
pre-push:
    RUSTFLAGS="{{warnings}}" RUSTDOCFLAGS="{{warnings}}" just lint test doc build

# ── CI ──────────────────────────────────────────────────────

ci: fmt-check lint test build doc

# Stable-channel best-effort sanity check; runs in a continue-on-error
# CI job so toolchain regressions surface without blocking PR merge.
ci-stable: lint-clippy-stable test-stable

# ── Release ─────────────────────────────────────────────────

# Releases are driven by `release-plz` in .github/workflows/release.yml:
# every push to `main` opens or updates a "Release v{version}" PR with
# the bump + CHANGELOG.md entry; merging the PR cuts the GitHub Release
# and tag. There is no local `just release` recipe — release-plz runs
# from the action, not from the workspace. To preview a release PR
# locally, install the binary (`cargo install release-plz`) and run
# `release-plz release-pr --dry-run`.
