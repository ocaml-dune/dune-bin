#!/usr/bin/env zsh

# Equivalent to `which dune`, but `which` might not be installed.
__dune_which() {
  echo "$PATH" | \
    tr ':' '\n' |\
    while read -r entry; do
      if test -x "$entry/dune"; then
        echo "$entry/dune"
        return 0
      fi
    done
    return 1
}

export __DUNE_SETUP_STATE="${__DUNE_SETUP_STATE:-incomplete}"

__dune_env() {
  if [ "$#" != "1" ]; then
    echo "__dune_env expected 1 argument, got $#"
    return
  fi
  local ROOT="$1"

  case "$__DUNE_SETUP_STATE" in
    incomplete)
      # This is the first time __dune_env has been called, so attempt to set up
      # the environment for dune and record in the global variable
      # __DUNE_SETUP_STATE whether or not it succeeded.

      # Add dune to PATH unless it's already present.
      # Affix colons on either side of $PATH to simplify matching (based on
      # rustup's env script).
      case :"$PATH": in
        *:"$ROOT/bin":*)
          # Do nothing since the bin directory is already in PATH.
          ;;
        *)
          export PATH="$ROOT/bin:$PATH"
          ;;
      esac

      if [ "$(__dune_which)" = "$ROOT/bin/dune" ]; then
        export __DUNE_SETUP_STATE=success

        # Only load completions if the shell is interactive.
        if [ -t 0 ]; then
          # completions via bash compat
          autoload -Uz compinit bashcompinit
          compinit
          bashcompinit
          . "$ROOT"/share/bash-completion/completions/dune
        fi

      else
        # Despite modifying the environment, running `dune` would resolve to
        # the wrong dune instance. This can happen if the bin directory
        # containing our dune was already present in PATH behind the bin
        # directory of the default opam switch.
        # TODO Possibly print a warning/hint in this case to help users fix
        # their environment.
        export __DUNE_SETUP_STATE=failure
      fi
      ;;
    success)
      # This is at least the second time this function was called in the
      # current environment (possibly by the user sourcing their shell config
      # or nesting shell sessions), and the previous time it was called it
      # successfully modified the environment to give precedence to our dune
      # executable. check that our dune still has precedence, and attempt to
      # undo any opam-specific path shenanigans that have taken place since the
      # last time this function was called.
      if [ "$(__dune_which)" != "$ROOT/bin/dune" ]; then
        case :"$PATH": in
          *:"$ROOT/bin":*)
            # Remove all opam bin directories from the PATH variable
            # between the start of the PATH variable and the first
            # occurrence of the dune binary distro's bin directory.
            PATH_MAYBE_FIXED=$(echo "$PATH" | \
              tr ':' '\n' |\
              sed "1,\#^$ROOT/bin\$# { \#^$HOME/.opam#d; }" |\
              paste -sd ':' -)
            # Only commit the change if it actually fixed the problem.
            if [ "$(PATH=$PATH_MAYBE_FIXED __dune_which)" = "$ROOT/bin/dune" ]; then
              export PATH="$PATH_MAYBE_FIXED"
            else
              # The attempt to fix the PATH variable failed, so give up.
              export __DUNE_SETUP_STATE=failure
            fi
            ;;
          *)
            # The dune binary distro is no longer in the PATH variable at
            # all, so give up.
            export __DUNE_SETUP_STATE=failure
            ;;
        esac
      fi
      ;;
    failure)
      # A previous attempt at modifying the environment failed, so don't
      # attempt further environment modifications here.
      ;;
  esac
}
