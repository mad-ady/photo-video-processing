#!/bin/bash

# run find +mediainfo and return a list of portrait videos

if [[ "$#" -ne 1 ]]; then
  echo "Usage $0 path-to-search"
  exit 1
fi


path=$1

find "$path" -type f \( -iname "*.mp4" \) -print0 | xargs -0 -I{} bash -c '
for file in "{}"; do
  height=$(mediainfo --Inform="Video;%Height%" "$file")
  if [[ "$height" -eq "2160" ]]; then 
    echo "$file"
  fi
done
'

