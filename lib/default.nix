{
  pkgs,
  lib ? pkgs.lib,
  flake,
  treefmtModule ? { },
}@args:

let

  treefmt = flake.inputs.treefmt-nix.lib.evalModule pkgs {
    imports = [
      ./treefmt.nix
      treefmtModule
    ];
  };

  shell = import ./shell { inherit pkgs treefmt; };
  callPackage = lib.callPackageWith args;

  attrs = callPackage ./attrs.nix { };
  fileList = callPackage ./file-list.nix { };
  script = callPackage ./script { };

  homeBasePath = flake + "/home";
  hostsBasePath = flake + "/hosts";
  nixosBasePath = flake + "/nixos";
  nixDarwinBasePath = flake + "/nix-darwin";
  nixOnDroidBasePath = flake + "/nix-on-droid";

in

{
  inherit
    homeBasePath
    nixosBasePath
    nixDarwinBasePath
    nixOnDroidBasePath
    ;

  inherit (attrs) attrsToList genAttrs';
  inherit (fileList) getFileList getRecursiveNixFileList getRecursiveDefaultNixFileList;
  inherit (script) mkScript;
  inherit (shell) mkShell;

  mkHomePath = p: homeBasePath + p;
  mkHostPath = host: p: hostsBasePath + "/${host}" + p;
  mkNixosPath = p: nixosBasePath + p;
  mkNixDarwinPath = p: nixDarwinBasePath + p;
  mkNixOnDroidPath = p: nixOnDroidBasePath + p;

  flake = {
    formatter = treefmt.config.build.wrapper;

    checks.formatting = treefmt.config.build.check flake;

    devShells = {
      default = shell.mkShell {
        name = "Nix Commons Flake";
      };
    };
  };
}
