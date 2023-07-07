#!/bin/bash

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
#   So, make sure you have 'GNU Parallel' and 'shntool' installed before running
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

export from_path=$(readlink -f "$1")
export to_path=$(readlink -f "$2")

filelist=$(find "$from_path/" -type f -iregex '.*\.flac$' -or -iregex '.*\.wav$')

echo ''

# ERROR MESSAGE #1
#   Exits if there is no collection directory OR nothing in it.
if ! [[ -d "$from_path" && "$(ls -A "$from_path")" ]]
then
    echo $'ERROR: No collection found.\n'
    exit 1
fi

# ERROR MESSAGE #2
#   Exits if there is an output directory AND something in it.
if [[ -d "$to_path" && "$(ls -A "$to_path")" ]]
then
    echo $'ERROR: Output directory is not empty.\n'
    exit 1
fi

# ERROR MESSAGE #3
#   Exits if there are duplicates between FLACs and WAVs in the collection.
filelist_test=$(echo "$filelist" | sed -e 's/\.flac$//gi' -e 's/\.wav$//gi')
if [[ "$(echo "$filelist_test" | sort | uniq -cd)" ]]
then
    echo $'ERROR: FLAC+WAV file name conflict detected.\n'
    exit 1
fi

# SUCCESS?

mkdir -p "$to_path"

splitFlac() {
    from_file="$1"
    to_file="$to_path${from_file#"$from_path"}"
    to_dir="$(dirname "$to_file")"
    cue_file="${from_file%.*}.cue"

    mkdir -p "$to_dir"

    echo "Processing: $from_file"
    if [[ "${from_file,,}" == *.flac || "${from_file,,}" == *.wav ]]
    then
        shnsplit -d "$to_dir" -f "$cue_file" -o flac -t "%n - %t" "$from_file"
    else
        cp "$from_file" "$to_file"
    fi
}

export -f splitFlac

echo "$filelist" | parallel -I% --max-args 1 splitFlac %
