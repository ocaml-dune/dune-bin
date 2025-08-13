#!/usr/bin/env zsh

__dune_env() {
  if [ "$#" != "1" ]; then
    echo "__dune_env expected 1 argument, got $#"
    return
  fi
  local ROOT="$1"

  # Add dune to PATH unless it's already present.
  # Affix colons on either side of $PATH to simplify matching (based on
  # rustup's env script).
  case :"$PATH": in
    *:"$ROOT/bin":*)
      # Do nothing since the bin directory is already in PATH.
      ;;
    *)
      # Prepending path in case a system-installed dune needs to be overridden
      export PATH="$ROOT/bin:$PATH"
      ;;
  esac

  # Only load completions if the shell is interactive.
  if [ -t 0 ]; then
    # completions via bash compat
    autoload -Uz compinit bashcompinit
    compinit
    bashcompinit
    . "$ROOT"/share/bash-completion/completions/dune
  fi
}
