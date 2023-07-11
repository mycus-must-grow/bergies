#!/bin/bash

# INFO: This shouldn't work. It is a draft.

# Set unofficial bash strict mode.
set -euxo pipefail
IFS=$'\n\t'

listfile=
listitem_root=
user=$(whoami)

usage()  #- this is a 82 characters wide ruler ;) ----------------------------------------#
{
    echo "Usage: dplhome.sh [item_list] [directory/]"
    echo
    echo "dplhome.sh links things to your home."
    echo
    echo "If you have an 'item_list' and a 'directory/', it will look for the items inside"
    echo "the list in the specified directory, and then link them in your home while"
    echo "keeping the original directory structure."
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

main()
{
    help_asked=$( printf '%s\n' "$@" | awk '/^-h$/ || /^--help$/ { print }' )
    if [ $# -gt 2 ] || [ "$help_asked" ]; then
        usage
        exit
    fi

    case $# in
        0)
            listitem_root=$( pwd -P )
            listfile=$( ls -Aw 1 )
            ;;
        1)
            if [ -d "$1" ]; then
                listitem_root=$1
                listfile=$( ls -Aw 1 "$listitem_root" )
            elif [ -f "$1" ]; then
                listitem_root=$( dirname "$1" )
                listfile=$( < "$1" )
            else
                usage
                exit
            fi
            ;;
        2)
            if [ -f "$1" ] && [ -d "$2" ]; then
                listitem_root=$2
                listfile=$( < "$1" )
            else
                usage
                exit
            fi
            ;;
    esac
}

main "$@"
