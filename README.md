# rust-template

[`cargo-generate`](https://github.com/cargo-generate/cargo-generate) template for new Rust projects with the following batteries included:

- **Pinned toolchain** via `rust-toolchain.toml`
- **Deterministic dev shell** via `shell.nix` + `.envrc` + `.tool-versions`
- **Task runner** via `justfile` with recipes for fmt / lint / test / build / doc / ci / pre-commit / pre-push / check-tool-versions
- **Pre-commit hooks** for fast checks (fmt-check + typos + cargo check) and slow checks (clippy + test + doc)
- **Conventional Commits enforcement** via `commitlint` (commit-msg hook + CI job)
- **Dependency audit** via `cargo-deny` (advisories, licenses, bans, sources)
- **Spell check** via `typos`
- **TOML formatting** via `taplo`
- **GitHub Actions CI** with a canonical-gate job (pinned tools), stable-advisory job (continue-on-error), and PR commitlint job
- **Automated releases** via [`semantic-release`](https://semantic-release.gitbook.io/) + [`semantic-release-cargo`](https://www.npmjs.com/package/semantic-release-cargo): every successful CI run on `main` triggers a release pass that bumps `Cargo.toml` + `Cargo.lock`, appends a `CHANGELOG.md` entry, pushes the `chore(release): <version>` commit directly to `main`, tags `v<version>`, and cuts a GitHub Release with the generated notes. The job is gated on a GitHub `environment: release` (one-time setup under *Settings → Environments*) so secrets and required reviewers live in one place. Crates.io publish is wired but disabled by default — flipping `"publish": false → true` in the `semantic-release-cargo` plugin block of `.releaserc.json` turns it on once `CRATES_API_KEY` is set in the environment. Bump rules are configurable in `.releaserc.json`'s `releaseRules` (default: `feat`/breaking → minor, `fix`/`perf`/`revert` → patch, `fix(ci)`/`chore`/etc. → skipped).
- **Workspace lints**: `forbid(unsafe_code)`, `warn(missing_docs)`, clippy `all` + `pedantic`

## Usage

### Install the generator

```sh
cargo install cargo-generate
```

### Generate a new project

```sh
cargo generate --git https://github.com/camercu/rust-template
```

You'll be prompted for:

| Prompt | Notes |
|---|---|
| `project-name` | kebab-case crate name |
| `authors` | `Name <email@example.com>` |
| `gh_username` | for the repository URL |
| `license` | one of `MIT OR Apache-2.0` (default), `MIT`, `Apache-2.0`, `MPL-2.0` |
| `kind` | `library` (default) or `binary` |
| `rust_toolchain_version` | pinned Rust version (default `1.88.0`) |

After generation:

```sh
cd <project-name>
nix-shell           # or: direnv allow
just setup          # installs hooks + npm devDeps
just ci             # runs the full check chain
```

## Local testing

To iterate on the template against a local checkout:

```sh
cargo generate --path /path/to/rust-template --name throwaway --destination /tmp
```

## Layout (template root)

```text
rust-template/
├── cargo-generate.toml      # Liquid placeholders + conditional file rules
├── post-script.rhai         # rhai hook: rename _README.md + _rust-toolchain.toml
├── README.md                # this file — template-repo docs (ignored at gen)
├── _README.md               # generated-project README (Liquid templated)
├── Cargo.toml               # tokenized
├── package.json             # tokenized (commitlint devDeps)
├── _rust-toolchain.toml     # renamed to rust-toolchain.toml at gen time
├── .tool-versions           # mirrors shell.nix; consumed by drift check
├── shell.nix                # pinned nixpkgs dev shell
├── .envrc                   # use nix
├── .gitignore
├── justfile
├── .pre-commit-config.yaml
├── commitlint.config.js
├── deny.toml
├── .typos.toml
├── .prettierrc.yaml
├── scripts/setup-dev.sh
├── .github/workflows/ci.yml
├── .github/workflows/release.yml
├── .releaserc.json             # semantic-release config (cargo publish disabled)
├── .taplo.toml                 # taplo exclusions (node_modules, target)
└── src/
    ├── lib.rs               # included only for kind == "library"
    └── main.rs              # included only for kind == "binary"
```

## License

This template is dual-licensed under MIT or Apache-2.0; pick whichever you prefer.
Generated projects pick their own license via the `license` prompt.
