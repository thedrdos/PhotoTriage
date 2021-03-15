clear

# Define work folder and work tree
WorkFolder=~/Pictures/ToBeProcessed

mkdir $WorkFolder 2>/dev/null
cd $WorkFolder
mkdir $WorkFolder/org   2>/dev/null # Folder for originals
mkdir $WorkFolder/jpgs  2>/dev/null # Folder for jpgs (for initial selection)
mkdir $WorkFolder/mov   2>/dev/null # Folder for video files
mkdir $WorkFolder/match 2>/dev/null # Folder for matched jpg+raw files

jpg="JPG" # JPG file extension
raw="RAF" # Raw file extension
mov="MOV" # Video file extension

fun_GoToOrg () {
    open -a Finder $WorkFolder/org
    }

fun_CopyJPGS () {
    cp  -a Finder $WorkFolder/org
    }

PS3='Please enter your choice: '
options=(
    "Open org folder" 
    "Copy JPGs from org to jpgs folder and open it" 
    "Option 3" 
    "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Open org folder")
            printf "Opening %s\n" $WorkFolder/org 
            open -a Finder $WorkFolder/org
            ;;
        "Copy JPGs from org to jpgs folder and open it" 
            printf "Copying JPGs to the jpgs folder and open it"
            cp $WorkFolder/org/*.$jpg $WorkFolder/jpgs/
            open $WorkFolder/jpgs
            ;;
        "Option 3")
            echo "you chose choice $REPLY which is $opt"
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
