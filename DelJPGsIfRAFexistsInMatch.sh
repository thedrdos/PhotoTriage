echo Name match files in jpg with raw files, if match then copy the raw to math otherwise copy the jpg
NFiles=$(ls ./match/*.JPG | wc -l)
printf "  Checking %s JPG files\n" $NFiles
count=0
for i in ./match/*.JP*; do
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
#    # Copy raw file if one exists with same name as jpg, otherwise just copy jpg
    [ -f "$i" ] || break # Break if no files found
    # Check if raw exists # del jpg since raw exists
    [ -f ./match/$(basename -- "$i" .JPG).RAF ] && \
        rm $i

done
printf "\r  100 %% Completed \n"

