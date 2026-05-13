# {{project-name}}

TODO: write a one-paragraph description of what this project does and why.

## Development

Pinned toolchain via [`rust-toolchain.toml`](./rust-toolchain.toml). Deterministic
dev shell via [`shell.nix`](./shell.nix) + [`.tool-versions`](./.tool-versions).

```sh
nix-shell           # or: direnv allow
just setup          # installs git hooks + npm devDeps
just ci             # full check chain (fmt-check, lint, test, build, doc)
```

`just --list` enumerates every available recipe.

## Releases

`.github/workflows/release.yml` runs on every push to `main` and hands
off to [`release-plz`](https://release-plz.dev/). From your
Conventional Commits the workflow:

- opens or updates a **release PR** (titled `chore: release <version>`)
  containing the version bump in `Cargo.toml`, the
  `[workspace.dependencies]` adjustments (if any), and the new
  `CHANGELOG.md` entry,
- waits for that PR's CI to pass and for you to merge it (any
  branch-protection rules on `main` apply to the release PR like any
  other PR),
- on merge, tags the resulting commit `v<version>` and cuts a GitHub
  Release with auto-generated notes.

Bump rules are configured in `release-plz.toml`'s `[changelog]`
section. By default `feat` and breaking changes bump minor, `fix` /
`perf` / `revert` bump patch, and `fix(ci)` / `chore` / `refactor` /
docs-style commits are skipped (no release for those). Edit
`commit_parsers` to tighten or relax.

Cargo publish to crates.io is wired but **disabled by default** —
`release-plz.toml` sets `publish = false` at the workspace level. The
workflow already exports `CARGO_REGISTRY_TOKEN` from the `release`
GitHub environment, so once the prerequisites below are in place,
enabling publishing is a one-line edit:

- **Enable**: flip `publish = true` in `release-plz.toml`.

Prerequisites (one-time, on the repository):

1. Create a GitHub environment named `release` under
   *Settings → Environments*. Add required reviewers or branch rules
   here if you want manual approval / branch protection on the
   release job.
2. Add a `CRATES_API_KEY` environment secret with a crates.io API
   token scoped for publishing (https://crates.io/me).
3. **Tag a baseline version before the first release run.** Without
   a prior `v*` tag, `release-plz` treats every prior commit as
   unreleased and the first PR will look enormous. Anchor the project
   to 0.x.y by tagging the current `main` HEAD as the same version
   `Cargo.toml` carries (e.g., `v0.1.0`):

   ```sh
   git tag -a v0.1.0 -m "Initial baseline release."
   git push origin v0.1.0
   ```
4. Allow GitHub Actions to create pull requests:
   *Settings → Actions → General → Workflow permissions →* tick
   *"Allow GitHub Actions to create and approve pull requests."*
   Without this, the `release-pr` step fails with a
   permission error when it tries to open the release PR.

To dry-run locally: install the binary with `cargo install
release-plz`, then `release-plz release-pr --dry-run` from the repo
root.

## License

Licensed under {{license}}.
