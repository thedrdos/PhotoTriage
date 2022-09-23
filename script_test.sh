# List all (potentially) external drives
clear
echo "$SHELL"

# funTest(){
#     declare -a arr=("${!1}")
#     echo "${arr[*]}"
#     arr+=( "extra" )
#     echo "${arr[*]}"
#     }

# funTestArr2(){
#     local -n arr=$1 
#     echo "${arr[*]}"
#     arr+=( "extra" )
#     echo "${arr[*]}"
# }


# arrstuff=( "this" "that" "other" )
# funTest arrstuff[@]
# echo "${arrstuff[*]}"
# echo "----"
# funTestArr2 arrstuff
# echo "${arrstuff[*]}"
# echo "----"

# funSelectWithDefault() {
#     # Custom `select` implementation that allows *empty* input.
#     # Pass the choices as individual arguments.
#     # Output is the chosen item, or "", if the user just pressed ENTER.
#     # Example:
#     #    choice=$(funSelectWithDefault 'one' 'two' 'three')
#    local item i=0 numItems=$# 

#   # Print numbered menu items, based on the arguments passed.
#   for item; do         # Short for: for item in "$@"; do
#     printf '%s\n' "$((++i))) $item"
#   done >&2 # Print to stderr, as `select` does.

#   # Prompt the user for the index of the desired item.
#   while :; do
#     printf %s "${PS3-#? }" >&2 # Print the prompt string to stderr, as `select` does.
#     read -r index
#     # Make sure that the input is either empty or that a valid index was entered.
#     [[ -z $index ]] && break  # empty input
#     (( index >= 1 && index <= numItems )) 2>/dev/null || { echo "Invalid selection. Please try again." >&2; continue; }
#     break
#   done

#   # Output the selected item, if any.
#   [[ -n $index ]] && printf %s "${@: index:1}"
# }
# choice=$(funSelectWithDefault 'one' 'two' 'three')
# echo "$choice"

# https://stackoverflow.com/questions/1063347/passing-arrays-as-parameters-in-bash
# takes_ary_as_arg()
# {
#     declare -a argAry1=("${!1}")
#     echo "${argAry1[@]}"

#     declare -a argAry2=("${!2}")
#     echo "${argAry2[@]}"
# }

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
        rsync -ac "${arr[i]}" "$dest"
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
        filematch=$(rsync -cv --stats "${arr[i]}" "./tmp/" | awk '/Number of files transferred: /{print $NF}')
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

extdrv=$(mount | grep "\ /Volumes/" | grep -o "/Volumes/[^(]*");
echo "$extdrv"
echo "-------"
# extdrv=

join_arr() {
  local IFS="$1"
  shift
  echo "$*"
}


# if funConfirm "Want this?" ; then
#     echo "oh you do, good"
#     else
#     echo "well then, I keep it"
# fi

if [ ! -z "$extdrv" ]; then
    IFS=$'\n' extdrvArray=($extdrv)
    for line in "${extdrvArray[@]}"; do
        echo "$line"
    done
    unset IFS

    echo "Choose an External Drive:"
    PS3='Please enter your choice: '
    select opt in "${extdrvArray[@]}" None;do
        opt=${opt% }
        # Check if the number in the response is within the integer lenght of the number of drives
        if [ $(($REPLY)) -le "${#extdrvArray[@]}" ] && [ $(($REPLY)) -ge 1 ]; then
            echo "yes"
            echo "You selected: $opt";

            # Find files
            jpgfiles_str=$(find "$opt" -type f -name '*.JPG' -not -path '*/.*');
            IFS=$'\n' jpgfiles_arr=($jpgfiles_str)

            rawfiles_str=$(find "$opt" -type f -name '*.RAF' -not -path '*/.*');
            IFS=$'\n' rawfiles_arr=($rawfiles_str)

            movfiles_str=$(find "$opt" -type f -name '*.MOV' -not -path '*/.*');
            IFS=$'\n' movfiles_arr=($movfiles_str)

            # Convert found files from string to array
            photofiles_arr=()
            photofiles_arr+=( "${jpgfiles_arr[@]}" )
            photofiles_arr+=( "${rawfiles_arr[@]}" )
            photofiles_arr+=( "${movfiles_arr[@]}" )

            # Declare found files
            echo "Found ${#jpgfiles_arr[@]} JPG files."
            echo "Found ${#rawfiles_arr[@]} RAF files."
            echo "Found ${#movfiles_arr[@]} MOV files."

            echo "Copying ${#photofiles_arr[@]} files"
            # rm -R -f tmp/* 

            funCopyFileArray photofiles_arr[@]  "./tmp/" 
            
            # echo "\n"

            # rm -R -f tmp/* 

            echo "Verifing ${#photofiles_arr[@]} files have been accurately copied"
            funVerifyCopyFileArray photofiles_arr[@]  "./tmp/"
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

        # case $opt in
        #     None) echo "None selected"
        #        break ;;
        #     *) echo "You selected: $opt";
        #         break ;;
        # esac
    done

else
    echo No mounted external drives to unmount
fi

# if [ ! -z "$extdrv" ]; then
#         while IFS= read -r line; do 
#             ((count++))
#             echo "$count"
#             # printf "Unmount %s\n" $line
#             ln=${line% }
#             echo "${ln}"
#             #diskutil umount "${ln}"  # remove the extra space in the paths
#         done <<< $extdrv 
#     else
#         echo No mounted external drives to unmount
#     fi