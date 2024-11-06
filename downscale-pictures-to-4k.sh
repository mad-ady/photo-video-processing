#!/bin/bash 
# Usage: downscale-image-to-4k.sh IMG*.jpg [IMG*.jpg...]

for srcfile
do
  case "$srcfile" in
  *.jpg) ;;
  *)
    echo "downscale-image-to-4k.sh: skipping '$srcfile': not an *.jpg file?" 2>&1
    continue
    ;;
  esac

  # Use mediainfo to get image height
  height=`mediainfo --Output=JSON "$srcfile" | jq '.media.track[] | select(.["@type"] == "Image") | .Height' | sed 's/"//g' | head -1`;

  if [ "$height" == 4500 ]; then
      # Get base filename: strip trailing .jpg
      # Example: IMG_20191216_153039.jpg becomes IMG_20191216_153039
      basedir=`dirname "$srcfile"`
      filename=`basename "$srcfile"`
      basefile=${filename%.jpg}
      if [ ! -r "$basedir/${basefile}_4k.jpg" ]; then
          echo "Downsampling $srcfile from $height to ${basefile}_4k.jpg (2250)";
          convert "$srcfile" -filter Lanczos -resize 4000x2250 "$basedir/${basefile}_4k.jpg"
      else
           echo "${basefile}_4k.jpg already exists, skipping";
      fi
   fi
done
