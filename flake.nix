{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-overlays = {
      url = "github:nix-ocaml/nix-overlays";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, flake-utils, nixpkgs, ocaml-overlays }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs { inherit system; }).appendOverlays
          [ ocaml-overlays.overlays.default ];

        # Returns a set of dune packages with keys "dynamic" and "static" which
        # correspond to a dynamically-linked and statically-linked instance of
        # dune, respectively.
        make-dune-pkgs = { ref, rev }: {
          dynamic = import ./dune.nix {
            inherit ref rev pkgs;
            static = false;
          };
          static = import ./dune.nix {
            inherit ref rev pkgs;
            static = true;
          };
        };
      in {
        packages = {
          dune = make-dune-pkgs {
            ref = "main";
            rev = "fd307dfd897c0d764bbf5b151e01f99f6be05111";
          };
        };
      });
}
