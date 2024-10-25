#!/bin/bash

# run find +mediainfo and return a list of portrait videos

if [[ "$#" -ne 1 ]]; then
  echo "Usage $0 path-to-search"
  exit 1
fi


path=$1

find "$path" -type f \( -iname "*.mp4" \) -print0 | xargs -0 -I{} sh -c '
for file in "{}"; do
  width=$(mediainfo --Inform="Video;%Width%" "$file")
  if [ "$width" -eq "2160" ]; then 
    #echo $file ${width}x${height}; 
    echo "$file"
  fi
done
'

