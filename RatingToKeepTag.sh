echo Tag jpgs photos with a non-zero rating as "Keep"
NFiles=$(ls ./jpgs/*.JPG | wc -l)
printf "  Checking %s JPG files\n" $NFiles
count=0
for i in ./jpgs/*.JP*; do
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
    # Read EXIF rating and tag the file "Keep" if rating is non-zero
    rat=$(exiftool -s -s -s -Rating $i)
    [[ $rat -ne 0 ]] && \
            xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>Keep</string></array></plist>' $i
done
printf "\r  100 %% Completed \n"
