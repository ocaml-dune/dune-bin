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
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays
          [ ocaml-overlays.overlays.default ];
        # Returns a set of dune packages with keys "dynamic" and "static" which
        # correspond to a dynamically-linked and statically-linked instance of
        # dune, respectively.
        make-dune-pkgs = { ref, rev }:
          let
            make-dune-pkg = { static }:
              import ./dune-versioned.nix {
                ref = ref;
                rev = rev;
                static = static;
                pkgs = pkgs;
              };
          in {
            dynamic = make-dune-pkg { static = false; };
            static = make-dune-pkg { static = true; };
          };
      in {
        packages = {
          dune_3_19_1 = make-dune-pkgs {
            ref = "3.19.1";
            rev = "76c0c3941798f81dcc13a305d7abb120c191f5fa";
          };
        };
      });
}
