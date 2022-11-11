{
  description = "Common flake library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks }:
    let
      name = "flake-commons";
      overlay = final: prev: {
        ${name} = prev.${name}.overrideAttrs (old: {
          src = builtins.path {
            inherit name;
            path = ./.;
          };
        });
      };
    in
    flake-utils.lib.eachSystem
      [ "aarch64-linux" "x86_64-linux" ]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {

          lib = import ./lib;

          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks.nixpkgs-fmt.enable = true;
            };
          };

          devShell = pkgs.mkShell {
            inherit name;

            buildInputs = with pkgs; [
              # banner printing on enter
              figlet
              lolcat

              nixpkgs-fmt
            ];

            shellHook = ''
              figlet ${name} | lolcat --freq 0.5
              ${(checks.pre-commit-check).shellHook}
            '';
          };
        }
      );
}
