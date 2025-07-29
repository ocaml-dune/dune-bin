{ ref, rev, static, pkgs, completion }:
let
  dune-src = fetchGit {
    url = "https://github.com/ocaml/dune";
    ref = ref;
    rev = rev;
  };
  completion-src = fetchGit {
    url = "https://github.com/gridbugs/dune-completion-scripts";
    inherit (completion) ref rev;
  };
  # This creates a git repo and creates an annotated tag named after the
  # current version of dune. This is necessary for the resulting dune
  # executable to print the correct version in the output of `dune --version`.
  version-tag-from-changelog = ''
    export PATH=${pkgs.git}/bin:$PATH
    export GIT_COMMITTER_NAME=user
    export GIT_COMMITTER_EMAIL=user@example.com
    export GIT_AUTHOR_NAME=user
    export GIT_AUTHOR_EMAIL=user@example.com
    git init
    git add .
    git commit --allow-empty -m dummy
    git tag ${ref} -am dummy
  '';
  dune = let
    pkgs' = if static then
      let arch = pkgs.stdenv.hostPlatform.parsed.cpu.name;
      in if arch == "x86_64" then
        pkgs.pkgsCross.musl64
      else if arch == "aarch64" then
        pkgs.pkgsCross.aarch64-multiplatform-musl
      else
        throw "Unsupported architecture: ${arch}"
    else
      pkgs;
  in pkgs'.stdenv.mkDerivation {
    pname = "dune";
    version = ref;
    src = dune-src;
    nativeBuildInputs = with pkgs'.ocamlPackages; [ ocaml ];
    strictDeps = true;
    preBuild = ''
      ${version-tag-from-changelog}
      ocaml boot/bootstrap.ml${if static then " --static" else ""}
      _boot/dune.exe subst
    '';
    buildFlags = [ "release" ];
    dontAddPrefix = true;
    dontAddStaticConfigureFlags = !static;
    configurePlatforms = [ ];
    preInstall = ''
      mkdir -p $out/share/bash-completion/completions
      cp ${completion-src}/bash.sh $out/share/bash-completion/completions/dune
      cp -r ${./extra}/* $out
    '';
    installFlags = [ "PREFIX=${placeholder "out"}" ];
  };
in dune
