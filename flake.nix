{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs { inherit system; });

        # Returns a set of dune packages with keys "dynamic" and "static" which
        # correspond to a dynamically-linked and statically-linked instance of
        # dune, respectively.
        make-dune-pkgs = { ref, rev, completion }: {
          dynamic = import ./dune.nix {
            inherit ref rev pkgs completion;
            static = false;
          };
          static = import ./dune.nix {
            inherit ref rev pkgs completion;
            static = true;
          };
        };
      in {
        packages = {
          dune = make-dune-pkgs {
            ref = "3.20.1";
            rev = "84b524ad0b337a95e44a7c307b1c237d20075272";
            completion = {
              url = "https://github.com/gridbugs/dune-completion-scripts";
              ref = "3.20.0";
              rev = "71fe0bb40c98a39e5626f7147407278d8ec9d0cf";
            };
          };
        };
      });
}
