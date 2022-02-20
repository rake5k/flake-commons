{ lib } @ args:

with lib;

let

  callPackage = callPackageWith args;

  attrs = callPackage ./attrs.nix { };
  fileList = callPackage ./file-list.nix { };

in

{
  inherit (attrs) attrsToList genAttrs';
  inherit (fileList) getFileList getRecursiveNixFileList getRecursiveDefaultNixFileList;
}
