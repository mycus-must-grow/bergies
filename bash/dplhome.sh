#!/bin/bash

# INFO: This shouldn't work. It is a draft.

# Set unofficial bash strict mode.
set -euxo pipefail
IFS=$'\n\t'

help_asked=$( printf '%s\n' "$@" | awk '/^-h$/ || /^--help$/ { print }' )
listfile=
listitem_root=
user=$(whoami)

usage()  #- this is a 82 characters wide ruler ;) ----------------------------------------#
{
    echo "usage: dplhome.sh [itemlist] [directory/]"
    echo
    echo "dplhome.sh links things to your home."
    echo
    echo "If you have an 'itemlist' and a 'directory/', it will look for the items inside"
    echo "the list in the directory, and then link them in your home while keeping the"
    echo "original directory structure."
    echo
    echo "An example of the itemlist's content:"
    echo
    echo "    Desktop"
    echo "    Videos"
    echo "    .bashrc.d"
    echo "    .config/yt-dlp"
    echo "    .ssh"
    echo
}

main()
{
    if [ $# -lt 1 ] || [ "$help_asked" ]; then
        usage
        exit
    fi
}

main "$@"
