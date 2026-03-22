# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

- **Build**: `nix build` – Builds the default output of the flake.
- **Check**: `nix flake check` – Runs all checks defined in the flake.  Checks include linting and any unit tests that may be added.
- **Format**: `nix fmt` – Runs the formatter `nixfmt-rfc-style` defined in `flake.nix`.
- **Run a single check**: `nix flake check --check <check-name>` – Replace `<check-name>` with the name of a specific check.  If no checks are defined, this command will report that none are available.
- **Launch dev shell**: `nix develop` – Starts a development shell with utilities such as `figlet` and `lolcat` pre‑installed.

## High‑Level Architecture

The repository is a small Nix flake that exposes a reusable library of utilities.  Its key components are:

1. **`flake.nix`** – The flake entry point.  It defines:
   - `lib`: Imported from the `lib` directory.
   - `formatter`: A formatter for all supported systems that uses `nixfmt-rfc-style`.
   - `checks`: A system‑specific set of checks that invoke the functions from `lib`.
   - `devShells`: A development shell per system that prints a banner with `figlet`/`lolcat` and sources a pre‑commit hook shell script.

2. **`lib` directory** – Contains reusable Nix modules:
   - **`attrs.nix`**: Provides helper functions `attrsToList` and `genAttrs'` for manipulating attribute sets.
   - **`file-list.nix`**: Offers functions to enumerate files in a directory tree, filtering by suffix.  These are used by the checks to discover files to process.
   - **`script.nix`**: (Currently missing but referenced in the flake – intended to provide a `mkScript` helper.)

3. **`checks` and `pre-commit-checks`** – Referenced by the flake but not present in the current snapshot.  When added, they would supply linting or test scripts that can be executed via `nix flake check`.

4. **Development shell** – The `devShell.default` entry installs utilities like `figlet` and `lolcat` and runs a shell hook that prints a colorful banner and sources any pre‑commit hook script.

## Usage Tips

- Run `nix flake check` to automatically format and lint the code.
- Use `nix develop` to enter a shell where you can experiment with the library functions in `flake.nix`.
- If you add new checks, name them descriptively and reference them in the `flake.nix` `checks` attribute set.

---

**Note**: This repository is a minimal example and does not contain unit tests at present.  Future contributors may add a `tests` directory and corresponding checks.
