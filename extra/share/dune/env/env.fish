#!/usr/bin/env fish

function __dune_env
    fish_add_path --prepend --path "$argv[1]/bin"
end
