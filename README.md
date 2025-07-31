# Dune Binary Distro

Nix flake for building binary releases of the Dune build system.

## Contents

Dune is distributed as a compressed tarball file (a `.tag.gz`) containing files
organized in a unix-style filesystem (`/bin`, `/share`, etc). No install script
is provided as yet however users can install these files by recursively copying
them into an appropriate directory such as `/usr/local`, `~/.local`, or `/opt`.
Supported platforms are currently x86_64-linux (statically linked with musl for
better compatibility with non-glibc distros), x86_64-macos and aarch64-macos.

## Installation

To install the binaries released here, use the 
[dune-bin-install](https://github.com/ocaml-dune/dune-bin-install) script, or
see that script for manual installation.

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

## Relationship with the "Dune Developer Preview"

The Dune Developer Preview is a nightly build of the tip of
[ocaml/dune](https://github.com/ocaml/dune)'s `main` branch, with all
experimental feature flags enabled. Its
[codebase](https://github.com/ocaml-dune/binary-distribution) contains machinery
for downloading and building dune every day, uploading built artifacts to a
webserver, a small website with information about the experimental features
it contains, and an installation script that downloads the latest version of
Dune and updates your shell config to make it available in `PATH`. By contrast,
this repo is intended to be a minimal way of producing binaries of stable
versions of dune which correspond with its release on the opam package manager.
