// Post-generation hook for cargo-generate.
// Runs after files are emitted but before the final summary.

// Rename _rust-toolchain.toml -> rust-toolchain.toml.
// The leading underscore in the template prevents rustup from honoring
// the literal `{{rust_toolchain_version}}` placeholder when anyone
// cd's into the template repo's working tree.
file::rename("_rust-toolchain.toml", "rust-toolchain.toml");

print("\n");
print("✓ Project scaffolded.\n");
print("\n");
print("Next steps:\n");
print("  1. cd into the project directory\n");
print("  2. Enter the dev shell:        nix-shell  (or: direnv allow)\n");
print("  3. Install hooks + node deps:  just setup\n");
print("  4. Verify everything works:    just ci\n");
print("\n");
print("Optional:\n");
print("  - Customize the description in Cargo.toml\n");
print("  - Adjust pinned tool versions in .tool-versions if needed\n");
print("  - Push to GitHub and watch .github/workflows/ci.yml run\n");
print("\n");
