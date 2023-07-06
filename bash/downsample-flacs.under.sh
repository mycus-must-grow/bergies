#!/bin/bash

# INFO: Under construction.

# WARNING: Don't source (.) this script. It sets shell options and exports
# variables.

#-------------------------------------------------------- downsample-flacs.sh -#
#
# WHAT DOES THIS DO?
#
#   This script should be used when you have a collection of HQ audio files
#   (FLACs and WAVs) and want to downsample them to 16-bit 48kHz.
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

# Bash strict mode:
set -euo pipefail
IFS=$'\n\t'

export from_collection=${1%"/"}
export to_collection=${2%"/"}

# Exits if there is no directory or nothing in it.
if ! [[ -d "$from_collection" && "$(ls -A "$from_collection")" ]]
then
    exit 1
fi

mkdir -p "$to_collection"

resampleFlac() {
    from_file=$1
    to_file="$to_collection/${from_file#"$from_collection"}"

    # Dirname never returns strings ending with "/",
    # unless the directory is the system root.
    to_dir=$(dirname "$to_file")
    mkdir -p "$to_dir"

    echo "Processing: $from_file"
    if [[ "$from_file" == *.flac ]]
    then
        sox -G "$from_file" -b 16 "$to_file" rate -v -L 48000 dither -s

        # Spectrogram stuff, feel free to discard the following 5 lines.
        mkdir "$to_dir/spectrals/"
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
