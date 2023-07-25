#!/bin/bash

# WARNING: Don't source (.) this script. It sets shell options.

# Set unofficial bash strict mode.
set -euo pipefail
IFS=$'\n\t'

fileList=
fromPath=

usage()
{
    echo "Usage: dplhome.sh [item_list] [directory/]"
    echo
    echo "dplhome.sh links things to your home."
    echo
    echo "If you have an 'item_list' and a 'directory/', it will look for the"
    echo "items inside the list in the specified directory, and then link them"
    echo "in your home while keeping the original directory structure."
    echo
    echo "An example of the itemlist's content:"
    echo
    echo "    Desktop"
    echo "    Videos"
    echo "    .bashrc.d"
    echo "    .config/yt-dlp"
    echo "    .ssh"
    echo
    echo "Options:"
    echo
    echo "    -h, --help:  Prints this."
}

initFromStdin()
{
    case $# in
        0)
            fileList=$( ls -Aw 1 )
            fromPath=$( pwd -P )
            ;;
        1)
            if [ -d "$1" ]; then
                fileList=$( ls -Aw 1 "$1" )
                fromPath=$1
            elif [ -f "$1" ]; then
                fileList=$( cat "$1" )
                fromPath=$( dirname "$1" )
            else
                usage
                exit
            fi
            ;;
        2)
            if [ -f "$1" ] && [ -d "$2" ]; then
                fileList=$( cat "$1" )
                fromPath=${2%'/'}
            elif [ -d "$1" ] && [ -f "$2" ]; then
                fileList=$( cat "$2" )
                fromPath=${1%'/'}
            else
                usage
                exit
            fi
            ;;
    esac
}

deployHome()
{
    while IFS= read -r line; do
        line=${line%'/'}

        # 1. Path already linked correctly.
        if [ "$HOME/$line" -ef "$fromPath/$line" ]; then
            printf "OK: '%s'\n" "$line"
            continue

        # 2. Path links to something else.
        elif [ -e "$HOME/$line" ] && [ -h "$HOME/$line" ]; then
            printf "CONFUSED: '%s'\n  Removing the link...\n" "$line"
            rm -f $HOME/$line

        # 3. The link is dead.
        elif ! [ -e "$HOME/$line" ] && [ -h "$HOME/$line" ]; then
            printf "DEAD: '%s'\n  Removing the link...\n" "$line"
            rm -f $HOME/$line

        # 4. Not a link.
        elif [ -e "$HOME/$line" ]; then
            printf "OTHER: '%s'\n  Doing nothing... You have to check it.\n" \
                "$line"
            continue

        # 5. We're in the clear.
        else
            printf "READY: '%s'\n" "$line"
        fi

        mkdir -p "$HOME/$(dirname "$line")"

        printf "  Linking... "
        ln -s "$fromPath/$line" "$HOME/$line" &> /dev/null && \
            printf "Linked Succesfully.\n" || \
            printf "Failed Succesfully.\n"
    done <<< "$fileList"
}

main()
{
    userName=$(whoami)
    userNeedsHelp= \
        $( printf '%s\n' "$@" | awk '/^-/ || /^-h$/ || /^--help$/ { print }' )

    if [ $# -gt 2 ] || [ "$userNeedsHelp" ]; then
        usage
        exit
    fi

    initFromStdin "$@"

    printf "\nLinking from '%s' into '%s' home...\n\n" "$fromPath" "$userName"

    deployHome

    echo
}

main "$@"
