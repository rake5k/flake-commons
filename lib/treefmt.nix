{ lib, config, ... }:

{
  projectRootFile = "flake.nix";

  programs = {
    # Nix dead code finder (targets *.nix)
    deadnix.enable = lib.mkDefault true;

    # Nix formatter (targets *.nix)
    nixfmt.enable = lib.mkDefault true;

    # Nix linter/fixer (targets *.nix)
    statix.enable = lib.mkDefault true;

    # Shell script linter (targets *.sh, *.bash)
    shellcheck.enable = lib.mkDefault true;

    # Shell script formatter (targets *.sh, *.bash)
    shfmt.enable = lib.mkDefault true;

    # Way faster version of prettier. Not all file types are yet supported.
    # If enabled, the extensions handled by biome are disabled in prettier automatically.
    biome = {
      # do not run checks (could be an alternative to eslint)
      formatCommand = lib.mkDefault "format";
      settings = {
        formatter.indentStyle = lib.mkDefault "space";
      };
    };

    # JS/TS, CSS, HTML, Markdown formatter (excludes YAML — handled by yamllint)
    prettier = {
      enable = lib.mkDefault true;
      excludes = (if config.programs.biome.enable then config.programs.biome.includes else [ ]) ++ [
        "*.yaml"
        "*.yml"
      ];
      settings.overrides = [
        {
          files = "*.md";
          options = {
            printWidth = 100;
            proseWrap = "always";
          };
        }
      ];
    };

    # YAML linter (targets *.yaml, *.yml)
    yamllint = {
      settings = {
        yaml-files = lib.mkDefault [
          "*.yaml"
          "*.yml"
        ];
        ignore = [
          ".copier-answers.yml"
        ];
        rules = {
          braces = {
            min-spaces-inside = lib.mkDefault 0;
            max-spaces-inside = lib.mkDefault 1;
            min-spaces-inside-empty = lib.mkDefault 0;
            max-spaces-inside-empty = lib.mkDefault 0;
          };
          brackets = {
            min-spaces-inside = lib.mkDefault 1;
            max-spaces-inside = lib.mkDefault 1;
            min-spaces-inside-empty = lib.mkDefault 0;
            max-spaces-inside-empty = lib.mkDefault 0;
          };
          colons = lib.mkDefault "enable";
          commas = lib.mkDefault "enable";
          comments = lib.mkDefault "enable";
          comments-indentation = {
            level = lib.mkDefault "warning";
          };
          document-end = lib.mkDefault "disable";
          document-start = lib.mkDefault "enable";
          empty-lines = lib.mkDefault "enable";
          empty-values = lib.mkDefault "disable";
          float-values = lib.mkDefault "disable";
          hyphens = lib.mkDefault "enable";
          indentation = lib.mkDefault "enable";
          key-duplicates = lib.mkDefault "enable";
          key-ordering = lib.mkDefault "disable";
          line-length = {
            level = lib.mkDefault "warning";
            max = lib.mkDefault 100;
            allow-non-breakable-inline-mappings = lib.mkDefault true;
          };
          new-line-at-end-of-file = lib.mkDefault "enable";
          new-lines = lib.mkDefault "enable";
          octal-values = lib.mkDefault "disable";
          quoted-strings = {
            quote-type = lib.mkDefault "double";
          };
          trailing-spaces = lib.mkDefault "enable";
          truthy = lib.mkDefault "enable";
        };
      };
    };
  };
}
