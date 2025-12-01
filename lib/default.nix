{
  pkgs,
  lib ? pkgs.lib,
  flake,
}@args:

with lib;

let

  callPackage = callPackageWith args;

  checks = import ./checks { inherit pkgs flake; };
  pre-commit-checks = import ./pre-commit-checks { inherit pkgs flake; };

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
    checks
    homeBasePath
    nixosBasePath
    nixDarwinBasePath
    nixOnDroidBasePath
    pre-commit-checks
    ;

  inherit (attrs) attrsToList genAttrs';
  inherit (fileList) getFileList getRecursiveNixFileList getRecursiveDefaultNixFileList;
  inherit (script) mkScript;

  formatter = pkgs.nixfmt-tree;

  mkHomePath = p: homeBasePath + p;
  mkHostPath = host: p: hostsBasePath + "/${host}" + p;
  mkNixosPath = p: nixosBasePath + p;
  mkNixDarwinPath = p: nixDarwinBasePath + p;
  mkNixOnDroidPath = p: nixOnDroidBasePath + p;
}
