{ lib }:

with builtins;
with lib;

{
  # attrsToList
  attrsToList = mapAttrsToList (name: value: { inherit name value; });

  # Generate an attribute set by mapping a function over a list of values.
  genAttrs' = values: f: listToAttrs (map f values);
}
