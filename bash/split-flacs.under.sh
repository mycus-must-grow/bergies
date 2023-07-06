#!/bin/bash

# INFO: Under construction.

# WARNING: Don't source (.) this script. It sets shell options and exports
# variables.

#------------------------------------------------------------- split-flacs.sh -#
#
# WHAT DOES THIS DO?
#
#   This is a bash script used to split multiple audio files (FLACs and WAVs)
#   that contain multiple songs in them; i.e.: if you run
#
#       sh split-flacs Collection/ Splitted/
#
#   And "Collection/" contains:
#
#       "Collection/Brown Bird/Fits of Reason.wav"
#       "Collection/Brown Bird/Fits of Reason.cue"
#       Collection/...
#       "Collection/Focus - Golden Oldies.flac"
#       "Collection/Focus - Golden Oldies.cue"
#
#   Then the script will split them into:
#
#       "Splitted/Brown Bird/Fits of Reason/01 - Seven Hells.flac"
#       "Splitted/Brown Bird/Fits of Reason/..."
#       "Splitted/Brown Bird/Fits of Reason/11 - Caves.flac"
#       Splitted/...
#       "Splitted/Focus - Golden Oldies/01 - Hocus Pocus.flac"
#       "Splitted/Focus - Golden Oldies/..."
#       "Splitted Focus - Golden Oldies/09 - Brother.flac"
#
# INFO
#
#   This is a script that uses multithreading to achieve a faster execution
#   time.
#
#   So, make sure you have GNU Parallel (and shntool) installed before running
#   this.
#
# USAGE
#
#   Substituting the <>'s:
#
#       sh split-flacs.sh <collection_of_albums_and_cues> <split_destination>
#
#------------------------------------------------------------------------------#

# Bash strict mode + print executed lines.
set -euxo pipefail
IFS=$'/n/t'

export from_path=${1%"/"}
export to_path=${2%"/"}

# Exits if there is no directory or nothing in it.
if ! [[ -d "$from_path" && "$(ls -A "$from_path")" ]]
then
    echo "> The script says: \"This means nothing\"."
    exit 1
fi

mkdir -p "$to_path"

splitFlac() {
    from_flac="$1"
    to_flac="$to_path${from_flac#"$from_path"}"
    to_dir="$(dirname "$to_flac")"
    cue_file="${from_flac%".flac"}.cue"

    shnsplit -d "$to_dir" -f "$cue_file" -o flac -t "%n - %t" "$from_flac"
}

export -f splitFlac

find "$from_path" -type f | parallel -I% --max-args 1 splitFlac %
