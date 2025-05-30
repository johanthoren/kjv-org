#!/bin/sh

usage="$(basename "$0") [-h] [-f|--force] -- Combine all org files in the current directory."

FORCE=0

while [ "$#" -gt 0 ]; do
    case $1 in
        -h|--help)
            echo "$usage"
            echo ""
            echo "Options:"
            echo "  -h, --help    Show this help message"
            echo "  -f, --force   Overwrite existing KJV.org without prompting"
            exit 0
            ;;
        -f|--force)
            FORCE=1
            ;;
        *)
            echo "Invalid option: $1"
            echo "Usage:"
            echo "$usage"
            exit 1
            ;;
    esac
    shift
done

OUT="KJV.org"
TEMP_OUT="$OUT.tmp"

# Check if output file exists and get user consent if needed
if [ -f "$OUT" ]; then
    if [ "$FORCE" -eq 1 ]; then
        echo "Force mode: Will overwrite existing $OUT upon successful completion."
    else
        while true; do
            read -r -p "The file $OUT already exists. Overwrite? [y/N] " input

            case $input in
                [yY])
                    echo "Will overwrite existing $OUT upon successful completion."
                    break
                    ;;
                [nN]|"")
                    echo "Aborting."
                    exit 0
                    ;;
                *)
                    echo "Please enter 'y' for yes or 'n' for no."
                    ;;
            esac
        done
    fi
fi

# Clean up any existing temporary file
if [ -f "$TEMP_OUT" ]; then
    rm "$TEMP_OUT"
fi

# Define the expected Bible book files in order
BIBLE_FILES="01_GEN.org 02_EXO.org 03_LEV.org 04_NUM.org 05_DEU.org 06_JOS.org 07_JDG.org 08_RUT.org 09_1SA.org 10_2SA.org 11_1KI.org 12_2KI.org 13_1CH.org 14_2CH.org 15_EZR.org 16_NEH.org 17_EST.org 18_JOB.org 19_PSA.org 20_PRO.org 21_ECC.org 22_SNG.org 23_ISA.org 24_JER.org 25_LAM.org 26_EZE.org 27_DAN.org 28_HOS.org 29_JOL.org 30_AMO.org 31_OBA.org 32_JON.org 33_MIC.org 34_NAM.org 35_HAB.org 36_ZEP.org 37_HAG.org 38_ZEC.org 39_MAL.org 40_MAT.org 41_MRK.org 42_LUK.org 43_JHN.org 44_ACT.org 45_ROM.org 46_1CO.org 47_2CO.org 48_GAL.org 49_EPH.org 50_PHP.org 51_COL.org 52_1TH.org 53_2TH.org 54_1TI.org 55_2TI.org 56_TIT.org 57_PHM.org 58_HEB.org 59_JAS.org 60_1PE.org 61_2PE.org 62_1JN.org 63_2JN.org 64_3JN.org 65_JUD.org 66_REV.org"

echo "Validating Bible book files..."
MISSING_FILES=""
for file in $BIBLE_FILES; do
    if [ ! -f "$file" ]; then
        MISSING_FILES="$MISSING_FILES $file"
    fi
done

if [ -n "$MISSING_FILES" ]; then
    echo "Error: Missing required files:"
    for file in $MISSING_FILES; do
        echo "  $file"
    done
    echo "Please ensure all 66 Bible book files are present."
    exit 1
fi

echo "All 66 Bible book files found."
echo "Processing all files with awk..."
awk '
BEGIN {
    # Print file header
    print "#+TITLE: The Holy Bible"
    print "#+SUBTITLE: King James Version (Authorized)"
    print "#+STARTUP: overview"
    print "#+OPTIONS: author:nil date:nil toc:2"
    print "#+LaTeX: \\setcounter{secnumdepth}{0}"
    print ""
    print "* Old Testament"
    print ""
    ot_printed = 1
    nt_printed = 0
}

# Convert chapter markers from * to ***
substr($0,1,2) == "* " { 
    gsub(/^[*] /, "*** ")
    print
    next 
}

# Convert titles from #+TITLE: to **
substr($0,1,8) == "#+TITLE:" { 
    sub(/^#\+TITLE: /, "** ")
    # Check if this is Matthew (first NT book) and we haven'\''t printed NT header yet
    if ($0 ~ /Matthew/ && !nt_printed) {
        print "* New Testament"
        print ""
        nt_printed = 1
    }
    print
    next 
}

# Convert author notes from #+AUTHOR_NOTE: to //
substr($0,1,14) == "#+AUTHOR_NOTE:" { 
    sub(/^#\+AUTHOR_NOTE: /, "//")
    print
    next 
}

# Print all other lines as-is
{ print }

# Add blank line between files
FNR == 1 && NR > 1 { print "" }
' $BIBLE_FILES > "$TEMP_OUT"

# Check if AWK processing was successful
if [ $? -ne 0 ] || [ ! -f "$TEMP_OUT" ]; then
    echo "Error: AWK processing failed."
    rm -f "$TEMP_OUT"
    exit 1
fi

echo "Validating processed content..."

# Check file size - should be close to expected ~4.3MB for the full Bible
FILE_SIZE=$(wc -c < "$TEMP_OUT")
if [ "$FILE_SIZE" -lt 4000000 ]; then
    echo "Error: Processed file is too small ($FILE_SIZE bytes). Expected around 4.3MB."
    rm -f "$TEMP_OUT"
    exit 1
fi

if [ "$FILE_SIZE" -gt 5000000 ]; then
    echo "Error: Processed file is too large ($FILE_SIZE bytes). Expected around 4.3MB."
    rm -f "$TEMP_OUT"
    exit 1
fi

# Check that the file has the expected header structure
if ! head -10 "$TEMP_OUT" | grep -q "#+TITLE: The Holy Bible"; then
    echo "Error: Processed file missing expected header."
    rm -f "$TEMP_OUT"
    exit 1
fi

# Check that Old Testament and New Testament sections exist
if ! grep -q "^\* Old Testament" "$TEMP_OUT"; then
    echo "Error: Old Testament section not found in processed file."
    rm -f "$TEMP_OUT"
    exit 1
fi

if ! grep -q "^\* New Testament" "$TEMP_OUT"; then
    echo "Error: New Testament section not found in processed file."
    rm -f "$TEMP_OUT"
    exit 1
fi

# Check that all Bible books are present (should have 66 ** entries for books)
BOOK_COUNT=$(grep -c "^\*\* " "$TEMP_OUT")
if [ "$BOOK_COUNT" -ne 66 ]; then
    echo "Error: Expected 66 Bible books, found $BOOK_COUNT in processed file."
    rm -f "$TEMP_OUT"
    exit 1
fi

# Check that Genesis and Revelation are in correct positions
if ! grep -A 5 "^\* Old Testament" "$TEMP_OUT" | grep -q "^\*\* Genesis"; then
    echo "Error: Genesis not found after Old Testament section."
    rm -f "$TEMP_OUT"
    exit 1
fi

if ! tail -500 "$TEMP_OUT" | grep -q "^\*\* Revelation"; then
    echo "Error: Revelation not found near end of file."
    rm -f "$TEMP_OUT"
    exit 1
fi

# Check that author notes were converted (should have some // lines)
AUTHOR_NOTE_COUNT=$(grep -c "^//" "$TEMP_OUT")
if [ "$AUTHOR_NOTE_COUNT" -eq 0 ]; then
    echo "Warning: No author notes found. This may be expected if none were present."
else
    echo "Found $AUTHOR_NOTE_COUNT author notes in processed file."
fi

# Check that no unconverted #+TITLE: lines remain (except the main header)
UNCONVERTED_TITLES=$(grep -c "^#+TITLE: " "$TEMP_OUT")
if [ "$UNCONVERTED_TITLES" -ne 1 ]; then
    echo "Error: Found $UNCONVERTED_TITLES #+TITLE: lines, expected exactly 1 (main header)."
    rm -f "$TEMP_OUT"
    exit 1
fi

echo "Content validation passed."

# Only now replace the original file with the successfully generated one
mv "$TEMP_OUT" "$OUT"

echo "All done."

exit 0

