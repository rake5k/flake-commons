{
  description = "Common flake library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      # System types to support.
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});

      mkLib =
        system:
        import ./lib {
          pkgs = nixpkgsFor."${system}";
          flake = self;
        };
    in
    {

      lib = import ./lib;

      formatter = forAllSystems (system: (mkLib system).flake.formatter);

      checks = forAllSystems (system: (mkLib system).flake.checks);

      devShells = forAllSystems (system: (mkLib system).flake.devShells);
    };
}
