#!/bin/sh
# This script is meant to be POSIX compatible, to work on as many different systems as possible.
# Please try to stick to this. Use a tool like shellcheck to validate changes.
set -eu

# The whole body of the script is wrapped in a function so that a partially
# downloaded script does not get executed by accident. The function is called
# at the end.
main () {
    install_root="$HOME/.dune"
    env_dir="$install_root/share/dune/env"
    bin_dir="${install_root}/bin"

    # Reset
    Color_Off='\033[0m' # Text Reset

    # Regular Colors
    Red='\033[0;31m'   # Red
    Green='\033[0;32m' # Green
    White='\033[0;0m'  # White

    # Bold
    Bold_Green='\033[1;32m' # Bold Green
    Bold_White='\033[1m'    # Bold White

    error() {
        printf "%berror%b: %s\n" "${Red}" "${Color_Off}" "$*" >&2
        exit 1
    }

    info() {
         printf "%b%s %b" "${White}" "$*" "${Color_Off}"
    }

    info_bold() {
        printf "%b%s %b" "${Bold_White}" "$*" "${Color_Off}"
    }

    success() {
        printf "%b%s %b" "${Green}" "$*" "${Color_Off}"
    }

    success_bold() {
        printf "%b%s %b" "${Bold_Green}" "$*" "${Color_Off}"
    }


    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }

    ensure_command() {
        command_exists "$1" || error "Failed to find \"$1\". This script needs \"$1\" to be able to install dune."
    }

    if [ "$#" != "1" ]; then
        echo "expected 1 argument, got $#"
        return
    fi
    version="$1"
    case $(uname -ms) in
        'Darwin x86_64')
            target=x86_64-apple-darwin
            ;;
        'Darwin arm64')
            target=aarch64-apple-darwin
            ;;
        'Linux x86_64')
            target=x86_64-unknown-linux-musl
            ;;
        *)
            error "The dune installation script does not currently support $(uname -ms)."
    esac
    tarball="dune-$version-$target.tar.gz"
    tar_uri="https://github.com/ocaml-dune/dune-bin/releases/download/$version/$tarball"
    # The tarball is expected to contain a single directory with this name:
    tarball_dir="dune-$version-$target"
    tmp_dir="$(mktemp -d -t dune-install.XXXXXXXXXX)"
    trap 'rm -rf "${tmp_dir}"' EXIT

    ensure_command "tar"
    ensure_command "gzip"
    ensure_command "curl"

    # Determine whether we can use --no-same-owner to force tar to extract with user permissions.
    touch "${tmp_dir}/tar-detect"
    tar cf "${tmp_dir}/tar-detect.tar" -C "${tmp_dir}" tar-detect
    if tar -C "${tmp_dir}" -xf "${tmp_dir}/tar-detect.tar" --no-same-owner; then
        tar_owner="--no-same-owner"
    else
        tar_owner=""
    fi
    tmp_tar="$tmp_dir/$tarball"

    curl --fail --location --progress-bar \
        --proto '=https' --tlsv1.2 \
        --output "$tmp_tar" "$tar_uri" ||
        error "Failed to download dune tar from \"$tar_uri\""

    tar -xf "$tmp_tar" -C "$tmp_dir" "${tar_owner}" > /dev/null 2>&1 ||
        error "Failed to extract dune archive content from \"$tmp_tar\""

    mkdir -p "$install_root"
    for d in "$tmp_dir/$tarball_dir"/*; do
        cp -r "$d" "$install_root"
    done

    already_installed=false

    unsubst_home() {
        echo "$1" | sed -e "s#^$HOME#\$HOME#"
    }

    remove_home() {
        echo "$1" | sed -e "s#^$HOME/##" | sed -e 's#^/##'
    }

    tildify() {
        case "$1" in
        "$HOME"/*)
            tilde_replacement=\~
            echo "$1" | sed "s|$HOME|$tilde_replacement|g"
            ;;
        *)
            echo "$1"
            ;;
        esac
    }

    case $(basename "${SHELL:-*}") in
        fish)
            env="${env_dir}/env.fish"
            env_file=$(unsubst_home "${env}")

            fish_config=$HOME/.config/fish/config.fish
            tilde_fish_config=$(tildify "$fish_config")

            # deliberately omit the home directory from the pattern so "~" and "$HOME" can be used interchangeably
            if [ -f "$fish_config" ] && match=$(grep -n "$(remove_home "${env}")" "$fish_config"); then
                echo "Shell configuration for dune appears to already exist in \"$fish_config\":"
                echo "$match"
                already_installed=true
                refresh_command="source $tilde_fish_config"
            elif [ -w "$fish_config" ]; then
                printf "\n# dune\n%s\n%s\n" "source $env_file" "__dune_env $(unsubst_home "$install_root")" >> "$fish_config"

                info "Added dune setup to \"$tilde_fish_config\""
                echo

                refresh_command="source $tilde_fish_config"
            else
                echo "To use dune you will need to source the file \"$env_file\""
                echo
            fi
            ;;

        zsh)
            env="${env_dir}/env.zsh"
            env_file=$(unsubst_home "${env}")

            zsh_config=$HOME/.zshrc
            tilde_zsh_config=$(tildify "$zsh_config")

            # deliberately omit the home directory from the pattern so "~" and "$HOME" can be used interchangeably
            if [ -f "$zsh_config" ] && match=$(grep -n "$(remove_home "${env}")" "$zsh_config"); then
                echo "Shell configuration for dune appears to already exist in \"$zsh_config\":"
                echo "$match"
                already_installed=true
                refresh_command="exec $SHELL"
            elif [ -w "$zsh_config" ]; then
                printf "\n# dune\n%s\n%s\n" "source $env_file" "__dune_env $(unsubst_home "$install_root")" >>"$zsh_config"

                info "Added dune setup to \"$tilde_zsh_config\""
                echo

                refresh_command="exec $SHELL"
            else
                echo "To use dune you will need to source the file \"$env_file\""
                echo
            fi
            ;;

        bash)
            env="${env_dir}/env.bash"
            env_file=$(unsubst_home "${env}")

            bash_configs="$HOME/.bashrc $HOME/.bash_profile"

            if [ "${XDG_CONFIG_HOME:-}" ]; then
                bash_configs="$bash_configs $XDG_CONFIG_HOME/.bash_profile $XDG_CONFIG_HOME/.bashrc $XDG_CONFIG_HOME/bash_profile $XDG_CONFIG_HOME/bashrc"
            fi

            for bash_config in $bash_configs; do
                # deliberately omit the home directory from the pattern so "~" and "$HOME" can be used interchangeably
                if [ -f "$bash_config" ] && match=$(grep -n "$(remove_home "${env}")" "$bash_config"); then
                    echo "Shell configuration for dune appears to already exist in \"$bash_config\":"
                    echo "$match"
                    refresh_command="source $bash_config"
                    already_installed=true
                    break
                fi
            done

            if [ "$already_installed" = false ]; then
                set_manually=true
                for bash_config in $bash_configs; do
                    tilde_bash_config=$(tildify "$bash_config")

                    if [ -w "$bash_config" ]; then
                        printf "\n# dune\n%s\n%s\n" "source $env_file" "__dune_env $(unsubst_home "$install_root")" >>"$bash_config"

                        info "Added dune setup to \"$tilde_bash_config\""
                        echo

                        refresh_command="source $bash_config"
                        set_manually=false
                        break
                    fi
                done

                if [ $set_manually = true ]; then
                    echo "To use dune you will need to source the file \"$env_file\""
                    echo
                fi
            fi
            ;;

        *)
            env="${env_dir}/env.bash"
            env_file=$(unsubst_home "${env}")

            echo "To use dune you will need to source the file \"$env_file\" (or similar as appropriate for your shell)"
            info_bold "  export PATH=\"$bin_dir:\$PATH\""
            echo
            ;;
    esac

    if [ "$already_installed" = false ]; then
        echo
        info "To get started, run:"
        echo

        if [ -n "${refresh_command+x}" ]; then
            info_bold "  $refresh_command"
            echo
        fi

        info_bold "  dune --help"
        echo
    fi

}
main "$@"
