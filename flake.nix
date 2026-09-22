{
  description = "Common flake library";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      flakeLib = import ./lib/flake.nix {
        inherit nixpkgs;
        treefmtNix = treefmt-nix;
      };
    in
    # formatter and checks.formatting are seeded by eachSystem.
    flakeLib.eachSystem { inherit self nixpkgs; } (
      pkgs: commonsLib: {
        inherit (commonsLib.flake) devShells;

        checks.lib-tests = import ./tests/lib-flake.nix {
          inherit pkgs nixpkgs;
          treefmtNix = treefmt-nix;
        };
      }
    )
    // {
      lib = {
        __functor = _: import ./lib;
        inherit (flakeLib) defaultSystems eachSystem;
      };
    };
}
