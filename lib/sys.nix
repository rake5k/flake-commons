{ pkgs, lib }:

let

  inherit (pkgs) system;

in

{
  isLinux = lib.hasInfix "linux" system;
  isDarwin = lib.hasInfix "darwin" system;
}
