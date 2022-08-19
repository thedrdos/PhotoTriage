###################################################################
# Setup - Initialization
###################################################################
clear
printf "\n"
# Define work folder and work tree
#WorkFolder=~/Pictures/ToBeProcessed
WorkFolder=${1:-~/Pictures/ToBeProcessed} 
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

funRatingToKeepTag (){
    echo Tag jpgs photos with a non-zero rating as "Keep"
    NFiles=$(ls $WorkFolder/jpgs/*.$jpg | wc -l)
    printf "  Checking %s JPG files\n" $NFiles
    count=0
    for i in $WorkFolder/jpgs/*.$jpg; do
        funProgressUpdate $count $NFiles
        (( count++ ))
        # Read EXIF rating and tag the file "Keep" if rating is non-zero
        rat=$(exiftool -s -s -s -Rating $i)
        [[ $rat -ne 0 ]] && \
                xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>Keep</string></array></plist>' $i
    done
    printf "\r  100 %% Completed \n"
}

funKeepToMatch (){
    echo Copying all JPGs in jpg and all RAF in raw with matching name to the folder match
    NFiles=$(mdfind 'kMDItemUserTags=Keep' -onlyin $WorkFolder/jpgs/ | wc -l)
    printf "  Attempting to match %s JPG files\n" $NFiles
    count=0

    mdfind 'kMDItemUserTags=Keep' -onlyin $WorkFolder/jpgs/ | while read i; do
        funProgressUpdate $count $NFiles
        (( count++ ))
        # Copy the raw file if one exists with same name as jpg
        [ -f "$i" ] || break # Break if no files found
        cp -n -p $i $WorkFolder/match/$(basename -- $i) # Copy jpgs, don't overwrite
        [ -f $WorkFolder/org/$(basename -- "$i" .$jpg).$raw ] && \
            cp -n -p $WorkFolder/org/$(basename -- "$i" .$jpg).$raw $WorkFolder/match # Copy matching raws
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

###################################################################
#  Menu
################################################################### 
PS3='Please enter your choice: '
options=(
    "Start:         Open org folder and external drives" 
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
        "Start:         Open org folder and external drives")
            echo $opt 
            printf "Manually copy pictures from external media to the org folder.\n"
            printf "\n"
            funBuildWorkFolder
            open -a Finder $WorkFolder/org
            funOpenMountedExternalDrives
            break
            ;;
        "Initialize:    Copy JPGs from org to jpgs folder, tag starred pics \"Keep\"")
            echo $opt
            funBuildWorkFolder
            cp -n -p $WorkFolder/org/*.$jpg $WorkFolder/jpgs/
            cp -n -p $WorkFolder/org/*.$mov $WorkFolder/mov/
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
            cp -n -p $WorkFolder/match/* "Keep-$(date +%Y%m%d)"
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