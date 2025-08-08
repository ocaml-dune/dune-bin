#!/usr/bin/env fish

function __dune_env
    set dune_bin_path "$argv[1]/bin"
    if ! contains "$dune_bin_path" $PATH;
        fish_add_path --prepend --path "$dune_bin_path"
    end
end
