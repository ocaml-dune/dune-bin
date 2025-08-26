# Dune Binary Distro

Build scripts for binary releases of the [Dune build
system](https://github.com/ocaml/dune). See the
[Releases](https://github.com/ocaml-dune/dune-bin/releases) page for this
project for pre-built binaries. The goal of this project is to provide stable
binary releases of Dune which can be installed without opam.


## Installation

To install the binary distro packages released here, use the
[dune-bin-install](https://github.com/ocaml-dune/dune-bin-install) script, or
see that script for manual installation. Alternatively, extract the package
archive into the root directory of a unix-looking directory structure
(typically a directory with at least a  "bin" and "share" subdirectory such as
"~/.local" or "/usr").

Download and run the install script to install the latest binary release of Dune with:
```
curl -fsSL https://github.com/ocaml-dune/dune-bin-install/releases/download/v2/install.sh | sh
```

The install script is interactive and will prompt before creating or modifying
any files on your computer.

## Contents

Dune is distributed as a compressed tarball file (a `.tag.gz`) containing files
organized in a unix-style filesystem (`/bin`, `/share`, etc). The tarball
contains the Dune executable and documentation, env scripts for setting up Dune
in various shells, and may contain a bash completion script for `dune` commands.


## Platform Support

Supported platforms are currently x86_64-linux (statically linked with musl for
better compatibility with non-glibc distros), x86_64-macos and aarch64-macos.


## Release Process

Modify the `flake.nix` file so that its `.#dune.dynamic` and `.#dune.static`
outputs are built from the desired revision of
[ocaml/dune](https://github.com/ocaml/dune). The `make-dune-pkgs` helper
function is provided to simplify this. Pass it a set with 3 elements:
- `ref` is the tag or branch name of the
  [dune repo](https://github.com/ocaml/dune) that will be built. It will _also_ be
  used to set the version number printed when running `dune --version`.
- `rev` is the revision of the [dune repo](https://github.com/ocaml/dune) that
  will be built. It's needed for reproducibility as in the case where `ref` is
  a branch.
- `completion` may be `null` or a set with keys `url`, `ref`, and `rev`
  pointing to a revision of a git repo containing a bash completion script
  named "bash.sh" (probably
  [this repo](https://github.com/gridbugs/dune-completion-scripts)). See below
  for more details about the completion script.

Here's an example:
```nix
packages = {
  dune = make-dune-pkgs {
    ref = "3.19.1";
    rev = "76c0c3941798f81dcc13a305d7abb120c191f5fa";
    completion = {
      url = "https://github.com/gridbugs/dune-completion-scripts";
      ref = "3.19.1";
      rev = "a56e105760f5cc49369ee012aa1b790f7443bd45";
    };
  };
};
```

You can test the change locally by running `nix build .#dune.dynamic`. Run the
resulting `dune` binary from `result/bin/dune`. The entire package build
process can be tested by running `./make_tarball.sh output .#dune.dynamic`
which will create a file in the current directory called `output.tar.gz`
containing the binary distro package build for your current OS/architecture.

Commit the changes and tag the commit with the corresponding version number
(`3.19.1` continuing the example above).

Push the tag to trigger a github action that builds the binary distro packages
for all supported platforms and makes them available on this project's releases
page.


## Completion Script

The [gridbugs/dune-completion-scripts repo](https://github.com/gridbugs/dune-completion-scripts) contains bash
completion scripts for Dune. Its release process is to tag commits with the
version of dune supported by the completion scripts in that commit. For example
tag `3.19.1` of the completion scrips repo will suggest command completions
matching the commands accepted by `dune.3.19.1`. Thus when releasing the binary
distro, choose a version of the completion scripts repo whose tag matches the
tag of Dune included in the release.

Dune does not contain a mechanism for generating its own completion script. The
completion script is generated using a semi-manual process. Dune uses the
[cmdliner](https://github.com/dbuenzli/cmdliner) library for its CLI which
currently lacks the ability to generate shell completion scripts. To generate
shell completion scripts for Dune, we replace its usage of cmdliner with an
alternative CLI library [climate](https://github.com/gridbugs/climate) which
can generate completion scripts. Climate provides a limited cmdliner
compatibility layer to simplify this process. There's also a
[branch](https://github.com/gridbugs/dune/tree/climate-3.20.0_alpha4) of Dune
(on gridbugs' fork) which can serve as a starting point where climate is
already vendored and a new command is added to Dune to print its completion
script. To generate completions for a particular version of Dune, rebase that
branch onto the desired revision of the Dune repo. Then follow the instructions
[here](https://github.com/gridbugs/dune-completion-scripts?tab=readme-ov-file#how-to-generate)
to generate the completion script.

If this is too complicated then bundling an older version of the completion
script with a later version of Dune could be considered, though it may be
better UX to have no completions at all than completions that omit valid
suggestions. It's recommended to only use an older version of the completion
script if the CLI hasn't changed since the last release of Dune.

To omit the completion script entirely, pass `completion = null;` to
`make-dune-pkgs`. E.g.
```
packages = {
  dune = make-dune-pkgs {
    ref = "3.19.1";
    rev = "76c0c3941798f81dcc13a305d7abb120c191f5fa";
    completion = null;
  };
};
```

Shell completion support for cmdliner is currently in development, so once this
work is complete Dune updates its vendored copy of cmdliner to include a
version with this feature, the process of generating completion scripts for
Dune will be greatly simplified.


## Env Scripts

This project contains environment scripts in extra/share/dune/env which are
included in the released tarballs. There is an env script for various shells
(bash, zsh, fish, and posix sh). The logic in the env script is to set up the
shell so that running `dune` at the command line invokes the Dune executable
from the binary distro. This involves modifying the `PATH` variable to include
the `bin` directory from the binary distro. To use the env script in a shell,
source the script appropriate for your shell and run the function `__dune_env`,
passing it the location of the binary distro. For example if the binary distro
is installed in ~/.local, the following will set up a bash shell environment:

```bash
. "$HOME/.local/share/dune/env/env.bash"
__dune_env "$HOME/.local"
```

For bash and zsh shells, this will also register bash completions for Dune in
the shell.

## Version Numbers

The version of Dune included in a package is determined by the `ref` passed to
`make-dune-pkgs` in flake.nix. This is both the snapshot of the Dune source
repository from which the binary distro is built, and also the value printed by
`dune --version`. Conversely, the version of the _binary distro_ package is
determined by the tag of this repo that was pushed to trigger the build of the
binary distro. This version appears in the filenames of packages (e.g.
`dune-3.19.1-aarch64-apple-darwin.tar.gz`) and also makes up the headings on
the project's releases page.

By convention we manually ensure that the version of the binary distro is the
same as the version of Dune contained within it by naming the tag of this repo
after the Dune `ref` passed to `make-dune-pkgs`. This policy may change in the
future.

One unfortunate consequence of this policy is that if the binary distro changes
as distinct from Dune (e.g. if the env or bash completion script changes), the
only way to update the binary distro to include these changes is to re-release
the same version by moving its tag to a commit containing the desired changes
and pushing it to github with `-f`. This causes the released tarballs to be
updated in place which is not ideal. Currently the install script doesn't
attempt to verify the checksum of the binary distro but if we ever add that
feature then we'll need to be more careful with how we update the binary distro
(one option would be to include an additional component in the binary distro's
version number so multiple different versions of the binary distro could be
released containing the same version of dune).


## Interactions with Opam

We expect many users of the Dune binary distro to have pre-existing
installations of opam, and for most opam switches to contain an installation of
Dune. Therefore depending on the order of entries in the user's `PATH` variable,
it's possible that the `dune` command could run the Dune executable from the
binary distro or the current opam switch.

The env scripts in the binary distro make changes to the user's `PATH`
variable in order to allow `dune` to be run from the command-line, but we try to
be as respectful of the user's `PATH` variable as we can. With this in mind, the
env scripts will not add an entry to the beginning of `PATH` if it's already
present somewhere later in `PATH`. This is because it's possible that the Dune
executable is not the only executable in its bin directory. Thus moving or
re-inserting its bin directory at the beginning of `PATH` may affect the
precedence of other unrelated executables, which we find unacceptable.

However this poses some problems when co-existing with opam.

Firstly, the default install location for Dune when using the install script is
~/.local, however it's possible that the user has already added ~/.local/bin to
their `PATH` when the install script runs. If ~/.local/bin is already in `PATH`,
and there's an opam switch earlier in `PATH` that ~/.local/bin, then if the Dune
binary distro is installed to ~/.local then any opam installation of Dune will
take precedence over the binary distro. The install script detects this case and
suggests installing the binary distro to ~/.dune instead, as it's unlikely that
~/.dune/bin is already in `PATH`.

The second problem comes from the fact that when opam is installed with its
default configuration, every time the shell config is re-loaded, opam will
re-insert the bin directory of the default switch at the beginning of `PATH`.
As described above, Dune's env scripts do not re-insert directories already in
`PATH`, so the second time Dune's shell initialization runs, it doesn't add its
bin directory to the beginning of `PATH`. This means that when a shell config is
reloaded, if the binary distro's Dune executable had precedence prior to
reloading, opam's installation of the Dune executable will have precedence after
reloading. Reloading a shell config is rare, but it's very surprising if doing
so changes which instance of the Dune executable runs when you run the command
`dune`. To fix this, Dune's shell initialization logic detects if the shell
config has been reloaded since the first time it ran, and if so, strips all the
opam bin directories out of `PATH` that come before the Dune binary distro's bin
directory. Eventually we'd like for opam's initialization logic to be changed to
not unconditionally prepend its bin directory into `PATH`. However even if this
happens many users will still be sourcing opam's current shell init scripts in
their shell config for the foreseeable future.

The third problem comes from the fact that opam's default configuration installs
a pre-command hook that runs immediately before every command runs. This is used
so that in projects with local opam switches, commands always run in the context
of that switch rather than requiring the user to run `eval $(opam env)`
explicitly (indeed the hook just runs `eval $(opam env)` automatically before
each command). This means that if the current opam switch contains an
installation of Dune then that Dune executable will run when the user runs the
`dune` command rather than the Dune binary from the binary distro, _no matter
what the `PATH` variable contains_. The env scripts don't attempt to fix this
problem, however the install script adds a line to the user's shell config that
removes the opam pre-command shell hook. This only takes effect if the Dune
binary distro shell initialization happens after opam's shell initialization,
which we take to mean that the user would prefer the `dune` command to resolve
to our executable rather than one from the opam switch. The user is still free
to run `eval $(opam env)` manually which will have the effect of giving
precedence to any `dune` executable in the current opam switch.


## Relationship with the "Dune Developer Preview"

The Dune Developer Preview is a nightly build of the tip of
[ocaml/dune](https://github.com/ocaml/dune)'s `main` branch, with all
experimental feature flags enabled. Its
[codebase](https://github.com/ocaml-dune/binary-distribution) contains machinery
for downloading and building dune every day, uploading built artifacts to a
webserver, a small website with information about the experimental features
it contains, and an installation script that downloads the latest version of
Dune and updates your shell config to make it available in `PATH`. It's similar
to the binary distro in that both projects distribute pre-compiled executables
of Dune installable with a shell script. Unlike the developer preview, the
binary distro releases stable versions of Dune with version numbers matching
those found in opam. It's not experimental, and intended for everyday use as an
alternative to installing Dune with opam.
