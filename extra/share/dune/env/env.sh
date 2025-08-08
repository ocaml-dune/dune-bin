#!/bin/sh

__dune_env() {
  if [ "$#" != "1" ]; then
    echo "__dune_env expected 1 argument, got $#"
    return
  fi
  __dune_root="$1"

  # Add dune to PATH unless it's already present.
  # Affix colons on either side of $PATH to simplify matching (based on
  # rustup's env script).
  case :"$PATH": in
    *:"$__dune_root/bin":*)
      # Do nothing since the bin directory is already in PATH.
      ;;
    *)
      # Prepending path in case a system-installed dune needs to be overridden
      export PATH="$__dune_root/bin:$PATH"
      ;;
  esac
}
