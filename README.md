# :snowflake: Flake Commons Library

[![NixOS][nixos-badge]][nixos]

Common library for Nix Flakes

## Usage

Add the flake as an input and build the per-system outputs with `eachSystem`:

```nix
{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    flake-commons.url = "github:rake5k/flake-commons";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-commons,
      ...
    }:
    flake-commons.lib.eachSystem
      {
        inherit self nixpkgs;
        treefmtModule = ./nix/treefmt.nix;
      }
      (
        pkgs: commonsLib: {
          devShells.default = commonsLib.mkShell { name = "My Project"; };
          packages.default = pkgs.callPackage ./nix/package.nix { };
        }
      );
}
```

`eachSystem` takes an argument set and a callback.

| Attribute       | Default                    | Meaning                                              |
| --------------- | -------------------------- | ---------------------------------------------------- |
| `self`          | required                   | Your flake. Backs `mkHomePath` and the other helpers |
| `nixpkgs`       | flake-commons' own nixpkgs | Nixpkgs flake used for `legacyPackages`              |
| `systems`       | `lib.defaultSystems`       | Systems to generate outputs for                      |
| `treefmtModule` | `{ }`                      | Extra treefmt module, as a path or an attrset        |

The argument set is closed, so a misspelled attribute fails evaluation rather than being ignored.

The callback receives `pkgs` and `commonsLib` and returns per-system outputs. `eachSystem` seeds
`formatter` and `checks.formatting` from `commonsLib`, merges your attrset over them, then adds the
system level: `packages.default` becomes `packages.<system>.default`. Setting `checks.mytest` adds
to the seeded checks; setting `checks.formatting` replaces it.

Outputs that are not per-system are merged outside the call:

```nix
flake-commons.lib.eachSystem { inherit self nixpkgs; } (pkgs: commonsLib: { })
// {
  nixosConfigurations.host = nixpkgs.lib.nixosSystem { };
}
```

`flake-commons.lib.defaultSystems` is `aarch64-darwin`, `aarch64-linux`, `x86_64-darwin`, and
`x86_64-linux`.

### Calling the library directly

`flake-commons.lib` is also callable, for cases that do not fit `eachSystem`:

```nix
commonsLib = flake-commons.lib {
  inherit pkgs;
  flake = self;
  treefmtModule = import ./nix/treefmt.nix;
};
```

This form resolves treefmt-nix from `flake.inputs.treefmt-nix`, so your flake must declare that
input. Pass `treefmtNix` explicitly to avoid it.

### What `commonsLib` provides

- `mkShell` — `pkgs.mkShell` with a figlet banner, the treefmt toolchain, and a pre-commit hook that
  formats staged files. Accepts `name`, `packages`, `shellHook`, `shellHookPost`.
- `mkScript name file path envs` — a shellcheck-verified script derivation.
- `attrsToList`, `genAttrs'` — attribute set helpers.
- `getFileList`, `getRecursiveNixFileList`, `getRecursiveDefaultNixFileList` — directory traversal.
- `mkHomePath`, `mkHostPath`, `mkNixosPath`, `mkNixDarwinPath`, `mkNixOnDroidPath` and the matching
  `*BasePath` attributes — paths relative to your flake.

<!-- prettier-ignore-start -->
[nixos]: https://nixos.org/
[nixos-badge]: https://img.shields.io/badge/NixOS-blue.svg?logo=NixOS&logoColor=white
<!-- prettier-ignore-end -->
