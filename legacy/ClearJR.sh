read -p "Are you sure you want to delete all jpg and raw files from jpgs and raws? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    rm ./jpgs/*
    rm ./raws/*
fi
