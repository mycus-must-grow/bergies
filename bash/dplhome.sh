#!/bin/bash

# INFO: This doesn't work. It is a draft.

set -euxo pipefail
IFS=$'\n\t'

usage()
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
    if [ $# -lt 1 ] ||                                                         \
       [ -n "$( { for arg in "$@"; do echo "$arg"; done } |                    \
            awk '/^-h$/ || /^--help$/ { print }' )" ]; then
        usage
        exit
    fi
}

main "$@"
