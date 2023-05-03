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

      # System types to support.
      supportedSystems = [ "aarch64-linux" "x86_64-darwin" "x86_64-linux" ];

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
            src = self;
            default_stages = [ "manual" "push" ];
            hooks = {
              # Nix
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              statix.enable = true;

              actionlint.enable = true;
              shellcheck.enable = true;
              markdownlint.enable = true;
            };
            settings = {
              # https://github.com/DavidAnson/markdownlint/blob/main/schema/.markdownlint.jsonc
              markdownlint.config = {
                "MD013" = {
                  code_blocks = false;
                  line_length = 100;
                  tables = false;
                };
              };
            };
          };

          deadnix = pkgs.runCommand "check-deadnix"
            { buildInputs = [ pkgs.deadnix ]; }
            ''
              deadnix
              touch ${placeholder "out"}
            '';

          nixpkgs-fmt = pkgs.runCommand "check-nixpkgs-fmt"
            { buildInputs = [ pkgs.nixpkgs-fmt ]; }
            ''
              nixpkgs-fmt --check ${self}
              touch ${placeholder "out"}
            '';

          statix = pkgs.runCommand "check-statix"
            { buildInputs = [ pkgs.statix ]; }
            ''
              statix check
              touch ${placeholder "out"}
            '';

          markdownlint = pkgs.runCommand "check-markdownlint"
            { buildInputs = [ pkgs.nodePackages.markdownlint-cli2 ]; }
            ''
              cd ${self}
              markdownlint-cli2
              touch ${placeholder "out"}
            '';

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
            ];

            shellHook = ''
              figlet ${name} | lolcat --freq 0.5
              ${self.checks.${system}.pre-commit-check.shellHook}
            '';
          };
        });
    };
}
