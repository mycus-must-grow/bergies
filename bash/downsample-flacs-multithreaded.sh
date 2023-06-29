#!/bin/bash

#------------------------------------------ downsample-flacs-multithreaded.sh -#
#
# Use this script like this, with respective paths instead of the <>'s:
#
#   downsample-flacs-multithreaded.sh <collection path> <destinated directory>
#
# This script assumes you have GNU Parallel installed.
#
#------------------------------------------------------------------------------#

# Bash strict mode:
set -euo pipefail
IFS=$'\n\t'

export from_collection=$1
export to_collection=$2

# Exits if there is no directory or nothing in it.
if ! [[ -d "$from_collection" && "$(ls -A "$from_collection")" ]]
then
  exit 1
fi

mkdir -p "$to_collection"

resampleFlac() {
  from_file=$1
  to_file=$to_collection${from_file#"$from_collection"}
  to_dir=$(dirname "$to_file")
  #
  echo "Processing: $from_file"
  if [[ "$from_file" == *.flac ]]
  then
    sox -G "$from_file" -b 16 "$to_file" rate -v -L 48000 dither -s
    #
    # Spectrogram stuff, feel free to discard the following 5 lines.
    mkdir -p "$to_dir"/spectrals/
    to_file_basename=$(basename "$to_file")
    to_filename_wo_ext="$to_dir/spectrals/${to_file_basename%.flac}"
    sox "$from_file" -n spectrogram -o "$to_filename_wo_ext".old.jpg
    sox "$to_file" -n spectrogram -o "$to_filename_wo_ext".new.jpg
  else
    mkdir -p "$to_dir"
    cp "$from_file" "$to_file"
  fi
    echo "Saved as: $to_file"
}
export -f resampleFlac

find "$from_collection" -type f | parallel -I% --max-args 1 resampleFlac %
