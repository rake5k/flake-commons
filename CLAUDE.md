# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Common Commands

- **Check**: `nix flake check` – Evaluates the flake and runs every check: `formatting` (treefmt
  over the whole tree) and `lib-tests` (`tests/lib-flake.nix`).
- **Run a single check**: `nix build .#checks.<system>.<name>`, for example
  `nix build .#checks.x86_64-linux.lib-tests`. There is no flag to select a check by name.
- **Format**: `nix fmt` – Runs treefmt. `lib/treefmt.nix` enables `nixfmt-rfc-style`, `deadnix`,
  `statix`, `shellcheck`, `shfmt`, and `prettier`; `biome` and `yamllint` are configured there but
  left disabled.
- **Launch dev shell**: `nix develop` – Starts a development shell with `figlet`, `lolcat`, the
  treefmt wrapper, and every formatter treefmt is configured to run. Entering it installs a
  `.git/hooks/pre-commit` that formats staged files.
- **Inspect outputs**: `nix flake show --all-systems` – Without the flag only the current system is
  listed.

The flake exposes no `packages` output, so a bare `nix build` fails.

## High‑Level Architecture

The repository is a small Nix flake that exposes a reusable library of utilities. Its key components
are:

1. **`flake.nix`** – The flake entry point. It builds `lib/flake.nix` from its own `nixpkgs` and
   `treefmt-nix` inputs, then expresses its own outputs through `eachSystem` — `formatter` and
   `checks.formatting` come from the seed, `devShells` and `checks.lib-tests` from the callback. The
   `lib` output is a functor: callable as `flake-commons.lib { pkgs, flake, ... }`, and carrying
   `eachSystem` and `defaultSystems` as attributes.

2. **`lib` directory** – Contains reusable Nix modules:
   - **`flake.nix`**: Provides `eachSystem`, the downstream entry point, plus `defaultSystems` and
     the `mergeOutputs`/`transpose` helpers it is built from. Takes `{ nixpkgs, treefmtNix }`.
   - **`attrs.nix`**: Provides helper functions `attrsToList` and `genAttrs'` for manipulating
     attribute sets.
   - **`file-list.nix`**: Offers functions to enumerate files in a directory tree, filtering by
     suffix. Consumed by downstream flakes, not by this repository's own checks.
   - **`script` directory**: Provides `mkScript` helper for generating shell scripts.

3. **Development shell** – `mkShell` in `lib/shell/default.nix` wraps `pkgs.mkShell`, adding
   `figlet`, `lolcat`, and the treefmt toolchain, printing a banner on entry, and writing a
   `.git/hooks/pre-commit` that runs treefmt over staged paths.

## Usage Tips

- `nix flake check` verifies formatting; it does not rewrite files. Use `nix fmt` to format.
- Use `nix develop` to enter a shell where you can experiment with the library functions in
  `flake.nix`.
- If you add new checks, name them descriptively and add them to the `eachSystem` callback in
  `flake.nix`. They merge alongside the seeded `formatting` check.

---

**Note**: `tests/lib-flake.nix` covers `lib/flake.nix` with `lib.runTests` and is wired in as the
`lib-tests` check. Add further tests there or alongside it, and reference them from the `eachSystem`
callback in `flake.nix`.
