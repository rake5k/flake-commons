{
  pkgs,
  nixpkgs,
  treefmtNix,
}:

let

  inherit (nixpkgs) lib;

  flakeLib = import ../lib/flake.nix { inherit nixpkgs treefmtNix; };

  inherit (flakeLib)
    defaultSystems
    eachSystem
    mergeOutputs
    transpose
    ;

  inherit (pkgs.stdenv.hostPlatform) system;

  # Stand-in for a derivation: lib.isDerivation only inspects the `type` attribute,
  # so this exercises the merge predicate without building anything.
  fakeDrv = name: {
    type = "derivation";
    inherit name;
  };

  # `self` is a plain path here: lib/default.nix uses `flake` only for path concatenation
  # and for the treefmt check, and treefmtNix is passed explicitly, so no `flake.inputs`
  # lookup happens.
  callEachSystem = eachSystem {
    self = ../.;
    inherit nixpkgs;
    systems = [ system ];
  };

  seeded = callEachSystem (_: _: { packages.default = fakeDrv "pkg"; });
  withCheck = callEachSystem (_: _: { checks.custom = fakeDrv "custom"; });
  withFormatter = callEachSystem (_: _: { formatter = fakeDrv "mine"; });

  transposedSingle = transpose { "x86_64-linux".packages.default = "d"; };

  transposedPair = transpose {
    "x86_64-linux".packages.default = "a";
    "aarch64-linux".packages.default = "b";
  };

  mergedFormatter = mergeOutputs { formatter = fakeDrv "old"; } { formatter = fakeDrv "new"; };

  mergedChecks = mergeOutputs { checks.formatting = fakeDrv "fmt"; } {
    checks.custom = fakeDrv "custom";
  };

  results = lib.runTests {

    testTransposeMovesSystemInside = {
      expr = transposedSingle;
      expected = {
        packages."x86_64-linux".default = "d";
      };
    };

    testTransposeMergesSystems = {
      expr = lib.attrNames transposedPair.packages;
      expected = [
        "aarch64-linux"
        "x86_64-linux"
      ];
    };

    testTransposeOfEmptyIsEmpty = {
      expr = transpose { };
      expected = { };
    };

    # Plain recursiveUpdate would recurse into both derivations instead of replacing.
    testMergeReplacesDerivations = {
      expr = mergedFormatter.formatter.name;
      expected = "new";
    };

    testMergeKeepsSiblingChecks = {
      expr = lib.attrNames mergedChecks.checks;
      expected = [
        "custom"
        "formatting"
      ];
    };

    testDefaultSystems = {
      expr = defaultSystems;
      expected = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    };

    testEachSystemSeedsFormatterAndChecks = {
      expr = lib.attrNames seeded;
      expected = [
        "checks"
        "formatter"
        "packages"
      ];
    };

    testEachSystemKeysOutputsBySystem = {
      expr = lib.attrNames seeded.packages;
      expected = [ system ];
    };

    testEachSystemSeedsFormattingCheck = {
      expr = lib.attrNames seeded.checks.${system};
      expected = [ "formatting" ];
    };

    testEachSystemCallerAddsToChecks = {
      expr = lib.attrNames withCheck.checks.${system};
      expected = [
        "custom"
        "formatting"
      ];
    };

    testEachSystemCallerOverridesFormatter = {
      expr = withFormatter.formatter.${system}.name;
      expected = "mine";
    };
  };

in

if results == [ ] then
  pkgs.runCommand "lib-flake-tests" { } "touch $out"
else
  throw "lib/flake.nix tests failed:\n${lib.generators.toPretty { } results}"
