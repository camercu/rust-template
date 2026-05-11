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

## License

Licensed under {{license}}.
