{
  description = "Common flake library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
    };
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      name = "flake-commons";

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
    in
    {

      lib = import ./lib;

      formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixfmt-rfc-style);

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        import ./lib/checks {
          inherit pkgs;
          flake = self;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          preCommitShellHook =
            (import ./lib/pre-commit-checks {
              inherit pkgs;
              flake = self;
            }).shellHook;
        in
        {
          default = pkgs.mkShell {
            inherit name;

            buildInputs = with pkgs; [
              # banner printing on enter
              figlet
              lolcat
            ];

            shellHook = ''
              figlet ${name} | lolcat --freq 0.5
              ${preCommitShellHook}
            '';
          };
        }
      );
    };
}
