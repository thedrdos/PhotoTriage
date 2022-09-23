###################################################################
# Setup - Initialization
###################################################################
clear
printf "\n"
# Define work folder and work tree
#WorkFolder=~/Pictures/ToBeProcessed
WorkFolder=${1:-~/Pictures/ToBeProcessed} 
# Define where the database file is for RAW Power (the macOS photo program)
RAWPowerDataBase=~/Library/Containers/com.gentlemencoders.RAWPower/Data/Documents/metadata.db
# Define default HEIC quality factor, upto 100, system default is 80
HEICquality=90 
HEICquality_default=$HEICquality

# Create work folders if needed
funBuildWorkFolder (){
    mkdir $WorkFolder 2>/dev/null
    mkdir $WorkFolder/org   2>/dev/null # Folder for originals
    mkdir $WorkFolder/jpgs  2>/dev/null # Folder for jpgs (for initial selection)
    mkdir $WorkFolder/mov   2>/dev/null # Folder for video files
    mkdir $WorkFolder/match 2>/dev/null # Folder for matched jpg+raw files
}
funBuildWorkFolder
cd $WorkFolder

jpg="JPG" # JPG file extension
raw="RAF" # Raw file extension
heic="HEIC" # HEIC file extension
mov="MOV" # Video file extension

###################################################################
# Functions
###################################################################

funProgressUpdate (){
    # Make progress indicator
    printf "  "
    case $(( $1 % 8 )) in
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
    printf "%2.0f %% Completed\r" $(($1*100/$2))
}

# https://brettterpstra.com/2017/08/22/tagging-files-from-the-command-line/
# https://www.linkedin.com/pulse/getting-setting-file-tags-via-command-line-os-x-boris-herman
funAddKeepTag (){
    xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>Keep</string></array></plist>' $1
}
funAdd1StarTag (){
    #xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>1Star</string></array></plist>' $1
    xattr -xw com.apple.metadata:_kMDItemUserTags $(echo '["Keep","1Star"]' | plutil -convert binary1 - -o - | xxd -p -c 256 -u) $1
    xattr -w com.apple.metadata:kMDItemStarRating 1 $1
}
funAdd2StarTag (){
    # xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>2Star</string></array></plist>' $1
    xattr -xw com.apple.metadata:_kMDItemUserTags $(echo '["Keep","2Star"]' | plutil -convert binary1 - -o - | xxd -p -c 256 -u) $1
    xattr -w com.apple.metadata:kMDItemStarRating 2 $1
}
funAdd3StarTag (){
    # xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>3Star</string></array></plist>' $1
    xattr -xw com.apple.metadata:_kMDItemUserTags $(echo '["Keep","3Star"]' | plutil -convert binary1 - -o - | xxd -p -c 256 -u) $1
    xattr -w com.apple.metadata:kMDItemStarRating 3 $1
}
funAdd4StarTag (){
    # xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>4Star</string></array></plist>' $1
    xattr -xw com.apple.metadata:_kMDItemUserTags $(echo '["Keep","4Star"]' | plutil -convert binary1 - -o - | xxd -p -c 256 -u) $1
    xattr -w com.apple.metadata:kMDItemStarRating 4 $1
}
funAdd5StarTag (){
    # xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>5Star</string></array></plist>' $1
    xattr -xw com.apple.metadata:_kMDItemUserTags $(echo '["Keep","5Star"]' | plutil -convert binary1 - -o - | xxd -p -c 256 -u) $1
    xattr -w com.apple.metadata:kMDItemStarRating 5 $1
}

funRatingToTag (){
    case $1 in
                    1 | "1")
                    funAdd1StarTag "$2"
                    ;;
                    2 | "2")
                    funAdd2StarTag "$2"
                    ;;
                    3 | "3")
                    funAdd3StarTag "$2"
                    ;;
                    4 | "4")
                    funAdd4StarTag "$2"
                    ;;
                    5 | "5")
                    funAdd5StarTag "$2"
                    ;;
                    *)
                    echo "Unrecognized star rating: $1"
                esac
}

funRatingToKeepTag (){
    echo Tag jpgs photos with a non-zero rating as "Keep"
    NFiles=$(ls $WorkFolder/jpgs/*.$jpg | wc -l)
    printf "  Checking %s JPG files for Keep Tags\n" $NFiles
    count=0
    for i in $WorkFolder/jpgs/*.$jpg; do
        funProgressUpdate $count $NFiles
        (( count++ ))
        # Read EXIF rating and tag the file "Keep" if rating is non-zero
        rat=$(exiftool -s -s -s -Rating $i)
        # [[ $rat -ne 0 ]] && \
        #     funAddKeepTag "$i"
        [[ $rat -ne 0 ]] && \
                funRatingToTag $rat $i
    done
    printf "\r  100 %% Completed \n"
}

funRAWPowerRatingToEXIF (){
    if [ -z "$RAWPowerDataBase" ]; then
        : 
        else # if there is no database given, then don't try to read it
        NFiles=$(ls $WorkFolder/jpgs/*.$jpg | wc -l)
        printf "  Checking %s JPG files for Ratings\n" $NFiles
        count=0
        countRating=0
        for i in $WorkFolder/jpgs/*.$jpg; do
            funProgressUpdate $count $NFiles
            (( count++ ))
            # Read the RAWPowerDataBase and write ratings to EXIF data and assign Keep
            rat=$(sqlite3 "$RAWPowerDataBase" "select rating from assets where filename = '$i' order by id DESC limit 1")
            # filename may not be unique in the table, so order by id (should represent order of when added) and only 1 to get latest entry
            if [ -z "$rat" ]; then
                :
                else  #check if rating is empty, i.e. probably didn't find the file
                # Assign the rating and a Keep tag
                exiftool -q -P -overwrite_original_in_place -Rating=$rat -RatingPercent=$(( $rat * 20 ))  "$i" 
                (( countRating++ ))
                # [[ $rat -ne 0 ]] && \
                #     funRatingToTag $rat $i
                # #     xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>Keep</string></array></plist>' $i
            fi
        done
        printf "\r  100 %% Completed - $countRating files rated\n"
    fi
}

funKeepToMatch (){
    funRAWPowerRatingToEXIF
    funRatingToKeepTag


    #read -t 4 # Pause 1 sec, hopefully the tag database catches up
    # not sure if this is needed, trying to make sure that the spotlight search works, i.e. has indexed properly the jpgs folder
    # mdimport $WorkFolder/jpgs/

    echo Copying all JPGs in jpg and all RAF in raw with matching name to the folder match
    NFiles=$(mdfind 'kMDItemUserTags=Keep' -onlyin $WorkFolder/jpgs/ | wc -l)
    printf "  Attempting to match %s JPG files\n" $NFiles
    count=0
    mdfind 'kMDItemUserTags=Keep' -onlyin $WorkFolder/jpgs/ | while read i; do
        funProgressUpdate $count $NFiles
        (( count++ ))
        # If a rating was assigned by RAW Power, then write it to the EXIF data and tag the file to keep
        # Copy the raw file if one exists with same name as jpg
        [ -f "$i" ] || break # Break if no files found
        # cp -n -p $i $WorkFolder/match/$(basename -- $i) # Copy jpgs, don't overwrite
        rsync -acE $i $WorkFolder/match/$(basename -- $i) # Copy jpgs, don't overwrite
        if [ -f $WorkFolder/org/$(basename -- "$i" .$jpg).$raw ] ; then
            # cp -n -p $WorkFolder/org/$(basename -- "$i" .$jpg).$raw $WorkFolder/match # Copy matching raws
            rsync -acE $WorkFolder/org/$(basename -- "$i" .$jpg).$raw $WorkFolder/match # Copy matching raws
            rat=$(exiftool -s -s -s -Rating $i) # copy the rating to the Raw file
            [[ $rat -ne 0 ]] && \
                exiftool -q -P -overwrite_original_in_place -Rating=$rat -RatingPercent=$(( $rat * 20 )) $WorkFolder/match/$(basename -- "$i" .$jpg).$raw 
                funRatingToTag $rat $WorkFolder/match/$(basename -- "$i" .$jpg).$raw 
        fi
    done
    printf "\r  100 %% Completed \n"
}

funDelJpgsIfRafExistsInMatch () {
    echo Deleting jpgs with mathing raw files in match foldeer
    NFiles=$(ls $WorkFolder/match/*.$jpg | wc -l)
    printf "  Checking %s JPG files\n" $NFiles
    count=0
    read -p "Are you sure you want to delete all the raw matched jpg files? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        for i in $WorkFolder/match/*.$jpg; do
            funProgressUpdate $count $NFiles
            (( count++ ))
        #    # Copy raw file if one exists with same name as jpg, otherwise just copy jpg
            [ -f "$i" ] || break # Break if no files found
            # Check if raw exists # del jpg since raw exists
            [ -f $WorkFolder/match/$(basename -- "$i" .$jpg).$raw ] && \
                rm $i
        done
        printf "\r  100 %% Completed \n"
    fi
}

funTagRawWoJpg () {
    echo Tag all RAF files that DO NOT have a JPG by same name, remove tag/s from others
    NFiles=$(ls $WorkFolder/match/*.$raw | wc -l)
    printf "  Checking %s RAF files\n" $NFiles
    count=0

    for i in $WorkFolder/match/*.$raw; do
        funProgressUpdate $count $NFiles
        (( count++ ))
    #    # Copy raw file if one exists with same name as jpg, otherwise just copy jpg
        [ -f "$i" ] || break # Break if no files found
        # Check if JPG exists # tag RAF if JPG doesn't exists
        [ -f $WorkFolder/match/$(basename -- "$i" .$raw).$jpg ] \
            || \
            xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>NoJPG</string></array></plist>' $i
        [ -f $WorkFolder/match/$(basename -- "$i" .$raw).$jpg ] \
            && \
            xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array></array></plist>' $i
    done
    printf "\r  100 %% Completed \n"
}

funExportToApplePhotos () {
    mkdir $WorkFolder/ToApplePhotos 2>/dev/null # Folder for matched jpg+raw files
    #vared -p "Quality percentage [0-100] (Apple default is 80): " -c HEICquality
    # read -p 'User to greet: ' -e -i 'Yoda' username
    #read -p "Quality percentage [0-100] (Apple default is 80): " -e -i $HEICquality HEICquality
    printf "Quality percentage [0-100], Default %s (Apple default is 80): " $HEICquality
    read tmpHEIC
    HEICquality="${tmpHEIC:=$HEICquality}"
    if [ $HEICquality -lt 0 ] || [ $HEICquality -gt 100 ]; then
        echo Invalid choice, must be between 0-100, using default $HEICquality_default
        HEICquality=$HEICquality_default
    fi
    # Rename all *.jpg to *.$jpg
    for f in $WorkFolder/match/*.jpg; do 
        mv -- "$f" "${f%.jpg}.$jpg"
    done
    NFiles=$(ls $WorkFolder/match/*.$jpg | wc -l)
    printf "  Converting %s JPG files\n" $NFiles
    count=0
    for i in $WorkFolder/match/*.$jpg; do
        funProgressUpdate $count $NFiles
        (( count++ ))
        funJpgToHeic $i $WorkFolder/ToApplePhotos/$(basename -- "$i" .$jpg).$heic
    done
    printf "\r  100 %% Completed \n"
}

funJpgToHeic () {
    # Convert jpg to heic, first argument is input file, second output file
    #sips -s format heic -s formatOptions80 jpgs/XT300394.JPG --out test.heic
    sips -s format heic -s formatOptions $HEICquality $1 --out $2 >> /dev/null
    # Get the creation date time stamp of the target file, saved as 't'.
    t="$(/usr/bin/GetFileInfo -d "$1")"
    # Set the modified and creation date time stamps of the target file to the saved value held in 't'.
    /usr/bin/SetFile -m "$t" -d "$t" "$2"
}

funTrashWorkspace () {
    funBuildWorkFolder
    cd $WorkFolder
    TrashFolder=$WorkFolder/forTrash-$(date +%Y%m%d)
    mkdir $TrashFolder 
    if [ -d $TrashFolder/org ]; then
        mv $WorkFolder/org/*   $TrashFolder/org/ 2>/dev/null # Folder for originals
        mv $WorkFolder/jpgs/*  $TrashFolder/jpgs/ 2>/dev/null # Folder for jpgs (for initial selection)
        mv $WorkFolder/match/* $TrashFolder/match/ 2>/dev/null # Folder for matched jpg+raw files
        if [  ! "$(ls -A $WorkFolder/org/)" ]; then 
            rm $WorkFolder/org/
        fi
        if [  ! "$(ls -A $WorkFolder/jpgs/)" ]; then 
            rm $WorkFolder/jpgs/
        fi
        if [  ! "$(ls -A $WorkFolder/match/)" ]; then 
            rm $WorkFolder/match/
        fi
    else
        mv $WorkFolder/org   $TrashFolder 2>/dev/null # Folder for originals
        mv $WorkFolder/jpgs  $TrashFolder 2>/dev/null # Folder for jpgs (for initial selection)
        mv $WorkFolder/match $TrashFolder 2>/dev/null # Folder for matched jpg+raw files]\
    fi
}

funOpenMountedExternalDrives () {
    # Gather the path/s for mounted external drives, there is an extra space at the end
    extdrv=$(mount | grep "\ /Volumes/" | grep -o "/Volumes/[^(]*")
    # Open the mounted exteral drives
    echo $extdrv
    if [ ! -z "$extdrv" ]; then
        while IFS= read -r line; do  
            ln=${line% }
            open "${ln}" # remove potential trailing space
        done <<< $extdrv   
    else
        echo No mounted external drives to open
    fi
}

funUnmountExternalDrives () {
    # Gather the path/s for mounted external drives, there is an extra space at the end
    extdrv=$(mount | grep "\ /Volumes/" | grep -o "/Volumes/[^(]*"); echo $extdrv
    # Unmount them all
    if [ ! -z "$extdrv" ]; then
        while IFS= read -r line; do 
            # printf "Unmount %s\n" $line
            ln=${line% }
            diskutil umount "${ln}"  # remove the extra space in the paths
        done <<< $extdrv 
    else
        echo No mounted external drives to unmount
    fi
}

funCopyFileArray(){
    # Copy files, 1st arg is array of source files, 2nd is destination folder
    # Example: 
    # copy_files=("file1.txt" "file2.txt")
    # funCopyFileArray copy_files[@] "./destination/"
    declare -a arr=("${!1}")
    local dest="$2"

    echo "Copying Files"
    funProgressUpdate 0 "${#arr[@]}"
    for i in "${!arr[@]}"; do
        funProgressUpdate $i "${#arr[@]}"
        rsync -acE "${arr[i]}" "$dest"
    done
    printf "\r  100 %% Completed \n"
}

funVerifyCopyFileArray(){
    # Verify copied files, 1st arg is array of source files, 2nd is destination folder
    # Example: 
    # copy_files=("file1.txt" "file2.txt")
    # funVerifyCopyFileArray copy_files[@] "./destination/"
    declare -a arr=("${!1}")
    local dest="$2"
    echo "Verifing File Copying"
    funProgressUpdate 0 "${#arr[@]}"
    allcopied=0
    unverified=()
    for i in "${!arr[@]}"; do
        funProgressUpdate $i "${#arr[@]}"
        filematch=$(rsync -cv --stats "${arr[i]}" "$dest" | awk '/Number of files transferred: /{print $NF}')
        if [ "$filematch" == "0" ]; then
            #no problem
            : # do nothing
        else
            # echo "Not copied: ${arr[i]}"
            allcopied=1
            unverified+=(${arr[i]})
        fi
    done
    printf "\r  100 %% Completed \n"
    if [[ $allcopied == 0 ]]; then
        echo "All Files Verified"; 
    else
        echo "The following files do NOT have verified copies (don't exist or non-identical):"
        for i in "${!unverified[@]}"; do
            echo "$unverified[i]"
        done
    fi
}

funConfirm (){
    # Prompt yes/no confirmation with no as default
    read -p "$1 (y/n - default no)" -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        return 0
    else 
        return 1
    fi
}

funCopyExternalOriginals (){
    extdrv=$(mount | grep "\ /Volumes/" | grep -o "/Volumes/[^(]*");
    # echo "$extdrv"
    # If external drives connected, offer to choose one to copy from
    if [ ! -z "$extdrv" ]; then
        IFS=$'\n' extdrvArray=($extdrv)
        for line in "${extdrvArray[@]}"; do
            echo "$line"
        done
        unset IFS

        echo "Choose an External Drive To Copy Images And Videos From:"
        PS3='Please enter your choice: '
        select opt in "${extdrvArray[@]}" None;do
            opt=${opt% }
            # Check if the number in the response is within the integer lenght of the number of drives
            if [ $(($REPLY)) -le "${#extdrvArray[@]}" ] && [ $(($REPLY)) -ge 1 ]; then
                echo "yes"
                echo "You selected: $opt";

                # Find files and convert to array of filenames
                jpgfiles_str=$(find "$opt" -type f -name "*.$jpg" -not -path "*/.*" 2>/dev/null);
                IFS=$'\n' jpgfiles_arr=($jpgfiles_str)

                rawfiles_str=$(find "$opt" -type f -name "*.$raw" -not -path "*/.*" 2>/dev/null);
                IFS=$'\n' rawfiles_arr=($rawfiles_str)

                movfiles_str=$(find "$opt" -type f -name "*.$mov" -not -path "*/.*" 2>/dev/null);
                IFS=$'\n' movfiles_arr=($movfiles_str)

                # Combine into one array of filenames
                photofiles_arr=()
                photofiles_arr+=( "${jpgfiles_arr[@]}" )
                photofiles_arr+=( "${rawfiles_arr[@]}" )
                photofiles_arr+=( "${movfiles_arr[@]}" )

                # Declare found files
                echo "Found ${#jpgfiles_arr[@]} $jpg files."
                echo "Found ${#rawfiles_arr[@]} $raw files."
                echo "Found ${#movfiles_arr[@]} $mov files."

                echo "Copying ${#photofiles_arr[@]} files"
                funCopyFileArray photofiles_arr[@]  "$WorkFolder/org/" 

                echo "Verifing ${#photofiles_arr[@]} files have been accurately copied"
                funVerifyCopyFileArray photofiles_arr[@]  "$WorkFolder/org" 
                # If successfully verified, then offer to delete all the originals
                if [[ $allcopied == 0 ]] ; then
                    echo "All copied, all well"
                    read -p "Delete all the copied files from the external device? (y/n - default no) " -n 1 -r
                    echo    # (optional) move to a new line
                    if [[ $REPLY =~ ^[Yy]$ ]]
                    then
                        funProgressUpdate 0 "${#photofiles_arr[@]}"
                        for i in "${!photofiles_arr[@]}"; do
                            funProgressUpdate $i "${#photofiles_arr[@]}"
                            rm "${photofiles_arr[i]}" 
                        done
                        printf "\r  100 %% Completed \n"
                    fi
                else
                    echo "Copy unsuccessful"
                fi
                break 
            else
                echo "no"
                echo "None selected"
                break 
            fi
        done
    else
        echo No mounted external drives to unmount
    fi
}

###################################################################
#  Menu
################################################################### 
PS3='Please enter your choice: '
options=(
    "Start:         Open org folder and external drives, copy photos and movies" 
    "Initialize:    Copy JPGs from org to jpgs folder, tag starred pics \"Keep\"" 
    "Match Keeps:   Copy JPGs from jpgs tagged \"Keep\", +raw from org, to match folder"
    "Del Matched:   Delete JPGs with matching raw files in match folder"
    "Tag Unmatched: Tag raw files with no matching JPG with \"NoJPG\""
    "Export:        Convert JPGs in match to HEIC in \"ToApple\""
    "Clean Up:      Keep, Trash"
    "Open Ext:      Open mounted external drives"
    "Unmount Ext:   Unmount mounted external drives"
    "Quit:          Terminate this menu - Also if any other entry not on this menu")

while true; do
    select opt in "${options[@]}"
    do
    clear
    printf "\n"
    case $opt in
        "Start:         Open org folder and external drives, copy photos and movies")
            echo $opt 
            printf "Copy photos and movies from external media to the org folder.\n"
            printf "\n"
            funBuildWorkFolder
            open -a Finder $WorkFolder/org
            funOpenMountedExternalDrives
            funCopyExternalOriginals
            break
            ;;
        "Initialize:    Copy JPGs from org to jpgs folder, tag starred pics \"Keep\"")
            echo $opt
            funBuildWorkFolder
            # cp -n -p $WorkFolder/org/*.$jpg $WorkFolder/jpgs/
            # cp -n -p $WorkFolder/org/*.$mov $WorkFolder/mov/
            rsync -acE $WorkFolder/org/*.$jpg $WorkFolder/jpgs/
            if [[ $( find $WorkFolder/org -name "*.$mov" | grep . ) ]]; then 
                rsync -acE $WorkFolder/org/*.$mov $WorkFolder/mov/
                fi
            funRatingToKeepTag
            open -a Finder $WorkFolder/jpgs/
            break
            ;;
         "Match Keeps:   Copy JPGs from jpgs tagged \"Keep\", +raw from org, to match folder")
            echo $opt
            funBuildWorkFolder
            funKeepToMatch
            open -a Finder $WorkFolder/match
            break
            ;;
        "Del Matched:   Delete JPGs with matching raw files in match folder")
            echo $opt
            funBuildWorkFolder
            funDelJpgsIfRafExistsInMatch
            open -a Finder $WorkFolder/match
            break
            ;;
        "Tag Unmatched: Tag raw files with no matching JPG with \"NoJPG\"")
            echo  $opt
            funBuildWorkFolder
            funTagRawWoJpg
            open -a Finder $WorkFolder/match
            break
            ;;
        "Export:        Convert JPGs in match to HEIC in \"ToApple\"")
            echo  $opt
            funExportToApplePhotos
            open -a Finder $WorkFolder/ToApplePhotos
            break
            ;;
        "Clean Up:      Keep, Trash")
            echo  $opt
            funBuildWorkFolder
            cd $WorkFolder
            echo "Copy match to Keep-TodaysDate"
            mkdir "Keep-$(date +%Y%m%d)"
            # cp -n -p $WorkFolder/match/* "Keep-$(date +%Y%m%d)"
            rsync -acE $WorkFolder/match/* "Keep-$(date +%Y%m%d)"
            echo "Clear the workspace: move jpgs, match and org into forTrash-date"
            funTrashWorkspace
            open -a Finder $WorkFolder
            break
            ;;
        "Open Ext:      Open mounted external drives")
            echo  $opt
            funOpenMountedExternalDrives
            break
            ;;
        "Unmount Ext:   Unmount mounted external drives")
            echo  $opt
            funUnmountExternalDrives
            break
            ;;
        "Quit:          Terminate this menu - Also if any other entry not on this menu")
            echo  $opt
            break 2
            ;;
        *) 
            #echo "invalid option $REPLY"
            echo Quitting Menu
            break 2
        ;;
    esac
done
done