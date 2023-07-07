#!/bin/bash

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
# SIDE-EFFECTS
#
#   Intended side-effects include:
#
#       1. Copying files that are neither FLAC or WAV to the new destination;
#       2. Rendering of spectrals to compare old files and new ones.
#
#------------------------------------------------------------------------------#

# Unofficial BASH strict mode.
set -euo pipefail
IFS=$'\n\t'

echo ''

# Canonicalize and export inputs.
export from_collection=$(readlink -f "$1")
export to_collection=$(readlink -f "$2")

# The 'filelist' variable here is only for error-checking purposes. That's
# probably not the best/most gracious solution. See error message #3.
filelist=$(find "$from_collection/" -type f -iregex '.*\.flac$' -or -iregex '.*\.wav$')

# ERROR MESSAGE #1
#   Exits if there is no collection directory OR nothing in it.
if ! [[ -d "$from_collection" && "$(ls -A "$from_collection")" ]]
then
    echo $'ERROR: No collection found.\n'
    exit 1
fi

# ERROR MESSAGE #2
#   Exits if there is an output directory AND something in it.
if [[ -d "$to_collection" && "$(ls -A "$to_collection")" ]]
then
    echo $'ERROR: Output directory is not empty.\n'
    exit 2
fi

# ERROR MESSAGE #3
#   Exits if there are duplicates between FLACs and WAVs in the collection.
filelist_test=''
for file_to_reduce in $filelist
do
    file_reduced=${file_to_reduce%.flac}
    file_reduce=${file_reduced%.FLAC}
    file_reduc=${file_reduce%.wav}
    file_redu=${file_reduc%.WAV}
    # Sorry. Had to make this pun.
    filelist_test+="$file_redu"$'\n'
done
filelist_test=${filelist_test%$'\n'}
does_filelist_contains_conflicts=$(sort <(echo "$filelist_test") | uniq -cd)
if [[ "$does_filelist_contains_conflicts" ]]
then
    echo $'ERROR: FLAC+WAV file name conflict detected.\n'
    exit 3
fi

# SUCCESS?

mkdir -p "$to_collection"

resampleFlac() {
    # This "$1" is not the same one from line #44, it is the file piped in the
    # last line.
    from_file=$(readlink -f "$1")
    to_file="$to_collection${from_file#"$from_collection"}"
    to_file="${to_file%.*}.flac"

    # Dirname never returns strings ending with "/", unless the directory is the
    # system root.
    to_dir=$(dirname "$to_file")
    mkdir -p "$to_dir"

    echo "Processing: $from_file"
    if [[ "${from_file,,}" == *.flac || "${from_file,,}" == *.wav ]]
    then
        sox -G "$from_file" -b 16 "$to_file" rate -v -L 48000 dither -s

        # Side-effect #1, feel free to discard the following 5 lines.
        mkdir -p "$to_dir/spectrals/"
        to_file_basename=$(basename "$to_file")
        to_filename_wo_ext="$to_dir/spectrals/${to_file_basename%.flac}"
        sox "$from_file" -n spectrogram -o "$to_filename_wo_ext.old.jpg"
        sox "$to_file" -n spectrogram -o "$to_filename_wo_ext.new.jpg"
    # Side-effect #2.
    else
        cp "$from_file" "$to_file"
    fi
    echo "Saved as: $to_file"$'\n'
}

export -f resampleFlac

find "$from_collection/" -type f | parallel -I% --max-args 1 resampleFlac %
