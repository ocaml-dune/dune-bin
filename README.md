# Dune Binary Distro

Nix flake for building binary releases of the Dune build system.

## Release Process

Modify the `flake.nix` file so that its `.#dune.dynamic` and `.#dune.static`
outputs are built from the desired revision of
[ocaml/dune](https://github.com/ocaml/dune). This should just involve setting
the `ref` and `rev` fields of the attribute set passed to `make-duve-pkgs`,
such as:
```nix
packages = {
  dune = make-dune-pkgs {
    ref = "3.19.1";
    rev = "76c0c3941798f81dcc13a305d7abb120c191f5fa";
  };
};
```

You can test the change locally by running `nix build .#dune.dynamic`. Run the
resulting `dune` binary from `result/bin/dune`.

Commit the changes and tag the commit with the corresponding version number
(`3.19.1` continuing the example above).

Once the github action completes building the binaries they'll be available in
the github "Release" page corresponding to the tag name.
