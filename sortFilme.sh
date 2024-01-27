#!/bin/bash
DIR=$1
EXT=$2
for filename in $DIR/*.$EXT; do
       width=`mediainfo "$filename"| grep Width | head -1 |cut -d ':' -f 2 | cut -d 'p' -f 1 | sed -E 's/\s+//g'`
       height=`mediainfo "$filename"| grep Height | head -1| cut -d ':' -f 2 | cut -d 'p' -f 1 | sed -E 's/\s+//g'`
       fps=`mediainfo "$filename"| grep FPS | head -1 | cut -d ':' -f 2 | cut -d 'F' -f 1 | sed -E 's/\s+//g'`
       echo "file '$filename'" | tee -a ${width}x${height}@$fps
done
