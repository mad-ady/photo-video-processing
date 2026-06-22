#!/bin/bash 
# Usage: insta360-rename-pictures-by-time.sh dir/

# Insta360 OneRS has a nasty "feature" to rename the photo filename based on when you download the picture via the Android App. 
# This script reverses this and recreates the original name from the description

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;32m'
NC='\033[0m' # No Color

dir=$1;

for file in "$dir/"*.jpg;
do
	#echo $file
    # use exiftool to see if it's a Insta360 OneRS photo
    is_one_rs=`exiftool -Model "$file" | cut -d ":" -f 2 | grep "Insta360 OneRS" | wc -l`
    if [ "$is_one_rs" == "1" ]; then
        echo $file;
        #TODO:
        # Extract  original date/time
        originalDescription=`exiftool -ImageDescription "$file" | cut -c 35-`;
        #TODO
        # name looks like IMG_20240815_175337_00_120.jpg
        if [[ -n "$originalDescription" && "$originalDescription" =~ .*\.jpg ]]; then
            basenameOriginal=`basename "$file"`;
            dirnameOriginal=`dirname "$file"`;
            newname="$originalDescription";
            echo -e "${YELLOW}Extracted original name: ${newname}${NC}"; 

            # if the new name is not the same as the original name...
            if [ "$newname" != "$basenameOriginal" ]; then 
                if [ ! -f "${dirnameOriginal}/$newname" ]; then
                    mv -n -v "$file" "${dirnameOriginal}/$newname" 
                    echo -e "${GREEN}Renamed $basenameOriginal to ${newname}${NC}"

                else
                    echo -e "${RED}Error - $newname exists. Not overwriting with ${basenameOriginal}${NC}"
                fi
            else
                # file is already renamed, or doesn't need renaming
                :
            fi


        else
            echo -e "${RED}Unable to extract a valid name from ${file}${NC}"
        fi
    else
        # non OneRS photo. No need (yet) to rename it.
        :
    fi


done
