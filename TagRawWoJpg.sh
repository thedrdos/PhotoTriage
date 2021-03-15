echo Tag all RAF files that DO NOT have a JPG by same name
NFiles=$(ls ./match/*.RAF | wc -l)
printf "  Attempting to match %s RAF files\n" $NFiles
count=0

for i in ./match/*.RAF; do
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
    # Check if JPG exists # tag RAF if JPG doesn't exists
    [ -f ./match/$(basename -- "$i" .RAF).JPG ] \
        || \
        xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>NoJPG</string></array></plist>' $i
    [ -f ./match/$(basename -- "$i" .RAF).JPG ] \
        && \
        xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array></array></plist>' $i
done
printf "\r  100 %% Completed \n"

