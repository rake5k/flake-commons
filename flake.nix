{
  description = "Common flake library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
    };
  };

  outputs = { self, nixpkgs, pre-commit-hooks }:
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

      # System types to support.
      supportedSystems = [ "aarch64-linux" "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {

      lib = import ./lib;

      checks = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              shellcheck.enable = true;
            };
          };

          shellcheck = pkgs.runCommand "shellcheck" { } ''
            shopt -s globstar
            echo 'Running shellcheck...'
            ${pkgs.shellcheck}/bin/shellcheck --check-sourced --enable all --external-sources --shell bash ${./.}/**/*.sh
            touch ${placeholder "out"}
          '';
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            inherit name;

            buildInputs = with pkgs; [
              # banner printing on enter
              figlet
              lolcat

              nixpkgs-fmt
              shellcheck
            ];

            shellHook = ''
              figlet ${name} | lolcat --freq 0.5
              ${(self.checks.${system}.pre-commit-check).shellHook}
            '';
          };
        });
    };
}
