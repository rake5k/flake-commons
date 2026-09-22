{
  nixpkgs,
  treefmtNix,
}:

let

  inherit (nixpkgs) lib;

  # A pattern default is evaluated in a scope that already contains the pattern's own
  # bindings, so `nixpkgs ? nixpkgs` below would be infinite recursion. Alias it first.
  defaultNixpkgs = nixpkgs;

  defaultSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];

  # Recursive update that stops at derivations. Derivations are attrsets, so a plain
  # recursiveUpdate would merge two of them attribute-wise instead of replacing one.
  mergeOutputs = lib.recursiveUpdateUntil (
    _path: l: r:
    !(lib.isAttrs l && lib.isAttrs r) || lib.isDerivation l || lib.isDerivation r
  );

  # { <system> = { packages.default = d; }; } -> { packages.<system>.default = d; }
  transpose =
    perSystem:
    lib.foldl' mergeOutputs { } (
      lib.mapAttrsToList (
        system: outputs: lib.mapAttrs (_: value: { ${system} = value; }) outputs
      ) perSystem
    );

  eachSystem =
    {
      self,
      nixpkgs ? defaultNixpkgs,
      systems ? defaultSystems,
      treefmtModule ? { },
    }:
    f:
    transpose (
      lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          commonsLib = import ./. {
            inherit pkgs treefmtModule treefmtNix;
            flake = self;
          };
        in
        mergeOutputs { inherit (commonsLib.flake) formatter checks; } (f pkgs commonsLib)
      )
    );

in

{
  inherit
    defaultSystems
    eachSystem
    mergeOutputs
    transpose
    ;
}
