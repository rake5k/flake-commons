{ lib }:

with lib;
with builtins;

let
  getFileList =
    recursive: isValidFile: path:
    let
      contents = readDir path;

      list = mapAttrsToList (
        name: type:
        let
          newPath = path + ("/" + name);
        in
        if type == "directory" then
          if recursive then getFileList true isValidFile newPath else [ ]
        else
          optional (isValidFile newPath) newPath
      ) contents;
    in
    flatten list;
in

{
  getFileList = getFileList false (_: true);
  getRecursiveNixFileList = getFileList true (hasSuffix ".nix");
  getRecursiveDefaultNixFileList = getFileList true (hasSuffix "default.nix");
}
