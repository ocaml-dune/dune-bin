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
            ref = "3.21.0";
            rev = "f38de6ecbde4238a2e9acfa8be0644ae3dd7cb3c";
            completion = {
              url = "https://github.com/gridbugs/dune-completion-scripts";
              ref = "main";
              rev = "42c6489d175cb81be58e052ca951186d6b2291d1";
            };
          };
        };
      });
}
