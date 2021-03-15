echo Copying all JPGs in jpg and all RAF in raw with matching name to the folder match
NFiles=$(mdfind 'kMDItemUserTags=Keep' -onlyin ./jpgs/ | wc -l)
printf "  Attempting to match %s JPG files\n" $NFiles
count=0

function (){echo This is a test; echo $(pwd)}

mdfind 'kMDItemUserTags=Keep' -onlyin ./jpgs/ | while read i; do
    # Make progress indicator
    printf "  "
    case $(( $count % 8 )) in
      0|1)
        printf "\134 "
        ;;
      2|3)
        printf "\174 "
        ;;
      4|5)
        printf "\057 "
        ;;
      6|7)
        printf "\055 "
        ;;
    esac
    printf "%2.0f %% Completed\r" $(($count*100/$NFiles))
    (( count++ ))
    # Copy the raw file if one exists with same name as jpg
    [ -f "$i" ] || break # Break if no files found
    cp $i ./match/$(basename -- $i) # Copy jpgs
    [ -f ./org/$(basename -- "$i" .JPG).RAF ] && \
        cp ./org/$(basename -- "$i" .JPG).RAF ./match # Copy matching raws
done
printf "\r  100 %% Completed \n"

