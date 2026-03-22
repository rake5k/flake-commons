{
  pkgs,
  treefmt,
}:

let

  inherit (pkgs) lib;

  treefmtTools = lib.concatStringsSep ", " (builtins.attrNames treefmt.config.build.programs);

  gitHook = ''
    echo ""
    echo -e "Active formatters (treefmt): \033[1;34m${treefmtTools}\033[0m"
    echo ""
    # Install pre-commit hook to run treefmt checks
    if [ -d .git ]; then
      # Transition: disable old pre-push hooks from nix-commons-flake < treefmt
      [ -f .git/hooks/pre-push ] && mv -f .git/hooks/pre-push .git/hooks/pre-push.legacy
      rm -f .pre-commit-config.yaml
      cat > .git/hooks/pre-commit << 'HOOK'
    #!/usr/bin/env bash
    echo "Running formatting checks..."
    if ! treefmt --fail-on-change; then
      echo ""
      echo "Formatting issues found. Run 'treefmt' to fix them."
      exit 1
    fi
    HOOK
      chmod +x .git/hooks/pre-commit
    fi
  '';

in

{
  mkShell =
    {
      name ? "Your Shell Name Here",
      packages ? [ ],
      shellHook ? "",
      shellHookPost ? "",
      ...
    }@args:
    pkgs.mkShell (
      (removeAttrs args [ "shellHookPost" ])
      // {
        inherit name;

        packages =
          packages
          ++ (with pkgs; [
            # banner printing on enter
            figlet
            lolcat
          ])
          ++ [ treefmt.config.build.wrapper ]
          ++ (builtins.attrValues treefmt.config.build.programs);

        shellHook = ''
          figlet ${name} | lolcat --freq 0.5
          ${shellHook}
          ${gitHook}
          ${shellHookPost}
        '';
      }
    );
}
