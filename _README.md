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

`.github/workflows/release.yml` runs after every successful CI run on
`main` and hands off to
[`semantic-release`](https://semantic-release.gitbook.io/) with the
[`semantic-release-cargo`](https://www.npmjs.com/package/semantic-release-cargo)
plugin. From your Conventional Commits the workflow:

- computes the next version from commit history,
- writes the bump into `Cargo.toml` + `Cargo.lock`,
- appends a `CHANGELOG.md` entry,
- pushes a `chore(release): <version>` commit straight to `main`,
- tags that commit `v<version>` and cuts a GitHub Release with the
  generated notes.

Bump rules live in [`.releaserc.json`](./.releaserc.json). Defaults:
`feat` and breaking changes bump minor; `fix` / `perf` / `revert` bump
patch; `fix(ci)` and `chore` / `refactor` / `docs` / `style` / `test`
/ `build` / `ci` commits are skipped (no release for those). Edit
`releaseRules` to tighten or relax.

Cargo publish to crates.io is wired but **disabled by default** —
`.releaserc.json` configures the `semantic-release-cargo` plugin with
`{ publish: false }`. The workflow already exports
`CARGO_REGISTRY_TOKEN` from the `release` GitHub environment, so once
the prerequisites below are in place, enabling publishing is a
one-line edit:

- **Enable**: change `"publish": false` to `"publish": true` in the
  `semantic-release-cargo` block of `.releaserc.json`.

Prerequisites (one-time, on the repository):

1. Create a GitHub environment named `release` under
   *Settings → Environments*. Add required reviewers or branch rules
   here if you want manual approval / branch protection on the
   release job.
2. Add a `CRATES_API_KEY` environment secret with a crates.io API
   token scoped for publishing (<https://crates.io/me>) — only needed
   when you flip `publish` on.
3. Allow GitHub Actions to push to protected branches. The release
   job commits `Cargo.toml` / `Cargo.lock` / `CHANGELOG.md` directly
   to `main`, so any branch-protection rules must exempt the
   `github-actions[bot]` actor or be relaxed for this workflow's
   `GITHUB_TOKEN`.

To dry-run locally: from a clean working tree, run
`npm ci && npx semantic-release --dry-run` (you need a personal
`GITHUB_TOKEN` exported for the GitHub plugin's checks to pass).

## License

Licensed under {{license}}.
