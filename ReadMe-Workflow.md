# Workflow for Lean Semi Manual Photo Importing And Processing

First, make sure the WorkFolder is set correctly in `Menu.sh` (default is: "~/Pictures/ToBeProcessed")

1. Copy all files from SD card to ../org folder 
2. Run Menu script (Make sure to set work directory in script)
3. Use Menu script - Initial org processing 
    * Copies all JPGs to jpgs from org
    * Tags starred images as "Keep"
    * Open Finder at jpgs (to facilitate "Keep" tagging)
3. Use Menu script - Match Keep JPGs 
    * Copy all JPGs from jpgs to match and also copy their raw counterparts from org to match, open match folder.
4. (Optional) Use Menu script - Delete JPGs with raw counterparts (leave single ones)
5. (Optional) Use Menu script - Tag all raws without JPG counterparts as "NoJPG" 
6. Manually review and/or edit the match folder files.
7. Use Menu script - Create Keep-[date] folder and copy match into it. 
    * Also Move jpgs, match, and org to Done-[date] folder in the work folder.
    * Open the work folder
8. Manually backup the Keep folder and delete the Done folder.




