{ ref, rev, static, pkgs }:
let
  dune-src = fetchGit {
    url = "https://github.com/ocaml/dune";
    ref = ref;
    rev = rev;
  };
  # This creates a git repo and creates an annotated tag named after the
  # current version of dune. This is necessary for the resulting dune
  # executable to print the correct version in the output of `dune --version`.
  version-tag-from-changelog = ''
    export PATH=${pkgs.git}/bin:$PATH
    export GIT_COMMITTER_NAME=user GIT_COMMITTER_EMAIL=user@example.com GIT_AUTHOR_NAME=user GIT_AUTHOR_EMAIL=user@example.com
    git init
    git add .
    git commit --allow-empty -m dummy
    git tag ${ref} -am dummy
  '';
  bootstrap-suffix = if static then " --static" else "";
  dune-overlay = self: super: {
    ocamlPackages = super.ocaml-ng.ocamlPackages_5_3.overrideScope
      (oself: osuper: {
        dune_3 = osuper.dune_3.overrideAttrs (a: {
          src = dune-src;
          preBuild = ''
            ${version-tag-from-changelog}
            ocaml boot/bootstrap.ml${bootstrap-suffix}
            _boot/dune.exe subst
          '';
        });
      });
  };
  pkgs-with-overlay = pkgs.appendOverlays [ dune-overlay ];
  dune-pkg = if static then
    pkgs-with-overlay.pkgsCross.musl64.ocamlPackages.dune
  else
    pkgs-with-overlay.ocamlPackages.dune;
in dune-pkg
