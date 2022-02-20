{ lib }:

with builtins;
with lib;

{
  # attrsToList
  attrsToList = attrs:
    mapAttrsToList (name: value: { inherit name value; }) attrs;

  # Generate an attribute set by mapping a function over a list of values.
  genAttrs' = values: f: listToAttrs (map f values);
}
