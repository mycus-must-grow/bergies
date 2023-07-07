#!/bin/bash

# INFO: Under construction.

# WARNING: Don't source (.) this script. It sets shell options and exports
# variables.

#-------------------------------------------------------- downsample-flacs.sh -#
#
# WHAT DOES THIS DO?
#
#   This script should be used when you have a collection of HQ audio files
#   (FLACs and WAVs) and want to downsample them to 16-bit 48kHz FLACs.
#
#   It stores the output in the same directory structure the original files
#   were, but in another location.
#
# INFO
#
#   This script uses multithreading to achieve a faster execution time.
#
#   So, make sure you have GNU Parallel (and SoX) installed before running it.
#
# USAGE
#
#   Substituting the <>'s:
#
#       sh downsample-flacs.sh <collection_path> <destinated_directory>
#
#------------------------------------------------------------------------------#

# Sets bash strict mode.
set -euo pipefail
IFS=$'\n\t'

# Read both inputs and canonicalize them. Also exports them for future reuse on
# piped shell, line #53.
export from_collection=$(readlink -f "$1")
export to_collection=$(readlink -f "$2")

# Exits if there is no directory or nothing in it.
if ! [[ -d "$from_collection" && "$(ls -A "$from_collection")" ]]
then
    exit 1
fi

mkdir -p "$to_collection"

resampleFlac() {
    # This "$1" is not the same one from line #38, it is the file piped in line
    # #79.
    from_file=$(readlink -f "$1")
    to_file="$to_collection/${from_file#"$from_collection"}"
    to_file="${to_file%.*}.flac"

    # Dirname never returns strings ending with "/", unless the directory is the
    # system root.
    to_dir=$(dirname "$to_file")
    mkdir -p "$to_dir"

    echo "Processing: $from_file"
    if [[ "${from_file,,}" == *.flac || "${from_file,,}" == *.wav ]]
    then
        sox -G "$from_file" -b 16 "$to_file" rate -v -L 48000 dither -s

        # Spectrogram stuff, feel free to discard the following 5 lines.
        mkdir -p "$to_dir/spectrals/"
        to_file_basename=$(basename "$to_file")
        to_filename_wo_ext="$to_dir/spectrals/${to_file_basename%.flac}"
        sox "$from_file" -n spectrogram -o "$to_filename_wo_ext.old.jpg"
        sox "$to_file" -n spectrogram -o "$to_filename_wo_ext.new.jpg"
    else
        cp "$from_file" "$to_file"
    fi
    echo "Saved as: $to_file"
}
export -f resampleFlac

find "$from_collection/" -type f | parallel -I% --max-args 1 resampleFlac %
