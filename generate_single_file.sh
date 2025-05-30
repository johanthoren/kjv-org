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

if [ -f "$OUT" ]; then
    if [ "$FORCE" -eq 1 ]; then
        echo "Force mode: Removing existing $OUT."
        rm "$OUT" || exit 1
    else
        read -r -p "The file $OUT already exits. Overwrite? [y/N] " input

        case $input in
            [yY][eE][sS]|[yY])
                echo "Removing existing $OUT."
                rm "$OUT" || exit 1
                ;;
            [nN][oO]|[nN]|"")
                echo "Aborting."
                exit 0
                ;;
            *)
                echo "Invalid input..."
                exit 1
                ;;
        esac
    fi
fi

echo "Combining all source files."
for file in *.org; do
    if [ ! "$file" = "README.org" ]; then
        cat "$file" >> "$OUT"
        echo "" >> "$OUT"
    fi
done

echo "Processing file with awk..."
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
' "$OUT" > "${OUT}.tmp" && mv "${OUT}.tmp" "$OUT"

echo "All done."

exit 0
