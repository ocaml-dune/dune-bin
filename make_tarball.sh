#!/usr/bin/env bash
set -eu

if [ "$#" -ne "2" ]; then
    echo "Usage: $0 NAME TARGET"
    echo
    echo "Creates a file NAME.tar.gz containing the dune binary distro."
    echo "TARGET is the nix target that gets built. It should be one of:"
    echo "  - .#dune.dynamic (builds a dynamically-linked dune executable)"
    echo "  - .#dune.static (builds a statically-linked dune executable)"
    exit 1
fi

NAME="$1"
TARGET="$2"

set -x

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
nix build "$TARGET"
cp -rL result "$tmp_dir/$NAME"
chmod -R u+w "$tmp_dir/$NAME"
pushd "$tmp_dir"
tar czf "$NAME.tar.gz" "$NAME"
popd
mv "$tmp_dir/$NAME.tar.gz" .
