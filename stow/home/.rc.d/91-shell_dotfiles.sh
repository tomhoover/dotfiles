# shellcheck shell=bash

# Load the shell dotfiles, and then some:
# * ~/.extra can be used for other settings you don’t want to commit.
load_shell_dotfiles()
                      {
    local file
    for file in ~/.{aliases,functions,envs,extra,SECRETS}; do
        # shellcheck disable=SC1090
        [ -r "$file" ] && [ -f "$file" ] && source "$file"
    done

    for file in ~/.config/dotfiles/$(uname).{aliases,functions,envs,extra}; do
        # shellcheck disable=SC1090
        [ -r "$file" ] && [ -f "$file" ] && source "$file"
    done

    for file in ~/.config/dotfiles/${MYHOST}.{aliases,functions,envs,extra}; do
        # shellcheck disable=SC1090
        [ -r "$file" ] && [ -f "$file" ] && source "$file"
    done
}

load_shell_dotfiles
