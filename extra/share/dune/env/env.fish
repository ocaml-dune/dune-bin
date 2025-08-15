#!/usr/bin/env fish

if ! set -q __DUNE_SETUP_STATE
    set --export __DUNE_SETUP_STATE "incomplete"
end

function __dune_env
    if [ "$(count $argv)" != "1" ]
        echo "__dune_env expected 1 argument, got $(count $argv)"
    end

    set --local dune_root "$argv[1]"
    set --local dune_bin "$dune_root/bin"

    switch "$__DUNE_SETUP_STATE"
        case incomplete
            if ! contains "$dune_bin" $PATH; and [ -d "$dune_bin" ]
                fish_add_path --prepend --path "$dune_bin"
            end
            if [ "$(type -P dune)" = "$dune_bin/dune" ]
                set --export __DUNE_SETUP_STATE "success"
            else
                # Despite modifying the environment, running `dune` would resolve to
                # the wrong dune instance. This can happen if the bin directory
                # containing our dune was already present in PATH behind the bin
                # directory of the default opam switch.
                # TODO Possibly print a warning/hint in this case to help users fix
                # their environment.
                set --export __DUNE_SETUP_STATE "failure"
            end
        case success
            # This is at least the second time this function was called in the
            # current environment (possibly by the user sourcing their shell config
            # or nesting shell sessions), and the previous time it was called it
            # successfully modified the environment to give precedence to our dune
            # executable. check that our dune still has precedence, and attempt to
            # undo any opam-specific path shenanigans that have taken place since the
            # last time this function was called.
            if [ "$(type -P dune)" != "$dune_bin/dune" ]
                if contains "$dune_bin" $PATH
                    # Remove all opam bin directories from the PATH variable
                    # between the start of the PATH variable and the first
                    # occurrence of the dune binary distro's bin directory.
                    set --local PATH_maybe_fixed $(printf "%s\n" $PATH | \
                        sed "1,\#^$dune_bin\$# { \#^$HOME/.opam#d; }")
                    # Only commit the change if it actually fixed the problem.
                    if [ "$(PATH=$PATH_maybe_fixed type -P dune)" = "$dune_bin/dune" ]
                        set --export PATH $PATH_maybe_fixed
                    else
                        # The attempt to fix the PATH variable failed, so give up.
                        set --export __DUNE_SETUP_STATE "failure"
                    end
                else
                    # The dune binary distro is no longer in the PATH variable at
                    # all, so give up.
                    set --export __DUNE_SETUP_STATE "failure"
                end
            end
        case failure
            # A previous attempt at modifying the environment failed, so don't
            # attempt further environment modifications here.
    end
end
