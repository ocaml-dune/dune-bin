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
            ref = "3.19.1";
            rev = "76c0c3941798f81dcc13a305d7abb120c191f5fa";
            completion = {
              ref = "3.19.1";
              rev = "a56e105760f5cc49369ee012aa1b790f7443bd45";
            };
          };
        };
      });
}
