#!/bin/bash

# WARNING: Don't source (.) this script. It sets shell options.

#------------------------------------------------------------- deploy-home.sh -#
#
#   Use this script like this, with respective paths instead of the <>'s:
#
#       deploy-home.sh <list.deploy> <the root dir the list refers to>
#
#   The <list.deploy> is just a text file (you can name it whatever), it should
#   contain lines like these and nothing else:
#
#       Desktop/
#       Documents/
#       Downloads/
#       Music/
#       Pictures/
#       Shelf/
#       Videos/
#       .config/nvim/
#       .config/yt-dlp/
#       .ssh/
#       .bashrc.d/
#       Robert
#       cheggs.ogg
#       .bashrc
#
#   The <root dir> is the parent directory from those files inside the list.
#
#   The script will then symlink all this stuff to the logged-in user's home.
#
#   Well, it will try to. You'll know if something is up.
#
#------------------------------------------------------------------------------#

# Set unnoficial bash strict mode:
set -euo pipefail
IFS=$'\n\t'

# Init variables:
#   Load script arguments:
backup_home=$(readlink -f $1)
list_to_deploy=$(readlink -f $2)

# Hello, you.
echo $'\nAs '$(whoami)$'\n#------- deploy-home.sh -#'

# Read <list.deploy> as a buffer and iterate with each newline. See line #89.
while IFS= read -r line
do
    line=${line%/}

    # Compare existing paths and see if they end up pointing to the same thing,
    # if yes: they are sort of linked.
    if   [ "$HOME/$line" -ef "$backup_home/$line" ]
    then
        echo $'@ '$line$'\n|                  Working'
        continue
    # If the first check (above) failed, it could mean they do not point to the
    # same address.
    elif [ -h "$HOME/$line" -a -e "$HOME/$line" ]
    then
        echo $'@ '$line$'\n|              Misdirected'
        rm -f $HOME/$line
    # And if the second check fails, it could mean the following 3 things:
    #   1st - There is a symlink, but nothing to point to;
    elif [ -h "$HOME/$line" -a ! -e "$HOME/$line" ]
    then
        echo $'@ '$line$'\n|                     Dead'
        rm -f $HOME/$line
    #   2nd - Something else is living there;
    elif [ -e "$HOME/$line" ]
    then
        echo $'@ '$line$'\n| DEAL WITH IT MANUALLY :P'
        continue
    #   3rd - It doesn't exist at all.
    else
        echo $'@ '$line$'\n|       Absolutely nothing'
    fi

    # Make parents
    mkdir -p "$HOME/$(dirname "$line")"

    # Link without squeaking
    ln -s "$backup_home/$line" "$HOME/$line" &> /dev/null

# Reads <list.deploy>'s content into our while loop. See line #50
done < "$list_to_deploy"

echo $'#------------------------#\n'
