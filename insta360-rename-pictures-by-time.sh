#!/bin/bash 
# Usage: insta360-rename-pictures-by-time.sh dir/

# Insta360 OneRS has a nasty "feature" to rename the photo filename based on when you download the picture via the Android App. 
# This script reverses this and recreates the original name (without the suffix).

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
        originalDateTime=`exiftool -DateTimeOriginal "$file" | cut -c 35-`;
        # date looks like 2024:08:15 17:53:37

        # split the date into bash variables
        read -r year month day hour minute second <<< `echo $originalDateTime | awk -F ' ' -F ':' '{print $1, $2, $3, $4, $5, $6;}'`
        if [ -n "$year" -a -n "$month" -a -n "$day" -a -n "$hour" -a -n "$minute" -a -n "$second" ]; then
            # we have a valid date
            echo -e "${YELLOW}Extracted original date time: ${year}-${month}-${day} ${hour}:${minute}:${second}${NC}"
            # rename file to original date/time
            basenameOriginal=`basename "$file"`;
            dirnameOriginal=`dirname "$file"`;
            newname="${year}${month}${day}_${hour}${minute}${second}.jpg"

            # if the new name is not the same as the original name...
            if [ "$newname" != "$basenameOriginal" ]; then 
                if [ ! -f "${dirnameOriginal}/$newname" ]; then
                    mv -n -v "$file" "${dirnameOriginal}/$newname" 
                    echo -e "${GREEN}Renamed $basenameOriginal to ${newname}${NC}"

                    # touch file to original date/time
                    touch -c -t "${year}${month}${day}${hour}${minute}.${second}" "${dirnameOriginal}/${newname}"
                else
                    echo -e "${RED}Error - $newname exists. Not overwriting with ${basenameOriginal}${NC}"
                fi
            else
                # file is already renamed, or doesn't need renaming
                :
            fi


        else
            echo -e "${RED}Unable to extract a valid date from $file"
        fi
    else
        # non OneRS photo. No need (yet) to rename it.
        :
    fi


done
