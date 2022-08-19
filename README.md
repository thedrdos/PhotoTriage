# PhotoTriage
A menu of shell scripts to help do rudimentary photo triage when importing photos from a camera memory card. Primarily for use with Fuji X mount camera memory cards and Apple computers. 

## Rudimentary Workflow
* Set the working folder in the menu shell script (default: '~/Pictures/ToBeProcessed')
* Run the menu script in a terminal window
* Insert SD card into an SD card reader
* Press 1 to open the 'org' folder and the memory card, manually copy or move all files into the 'org' folder.
* Press 2 to copy all 'JPG' files to the 'jpgs' folder.
* Use the Finder gallery view and shortcut keys (custom) to tag files as *keep* (files with a star rating in their EXIF data will automatically be tagged as *keep*)
* Press 3 to match all *keep* 'JPG' files with their 'RAF' (raw files) counterparts, copy both to the 'keep' folder.
* Optional: Press 6 to convert all 'JPG's in 'match' to 'HEIC' files in the 'ToApple" folder, then drag all the files in the 'ToApple' folder into the Import folder in the Photos app to import them into your Photos library.
