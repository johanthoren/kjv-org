#!/bin/sh

usage="$(basename "$0") [-h] -- Combine all org files in the current directory."

if [ -n "$1" ]; then
    case $1 in
        -h)
            echo "$usage"
            exit 0
            ;;
        *)
            echo "Invalid option or argument."
            echo "Usage:"
            echo "$usage"
            exit 1
            ;;
    esac
fi

OUT="KJV.org"

if [ -f "$OUT" ]; then
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

echo "Combining all source files."
for file in *.org; do
    if [ ! "$file" = "README.org" ]; then
        cat "$file" >> "$OUT"
        echo "" >> "$OUT"
    fi
done

echo "Moving all chapter markers two steps to the right."
sed -i'' 's/^\*\ /\*\*\*\ /g' "$OUT"
echo "Converting TITLEs."
sed -i'' 's/^#+TITLE\:\ /\*\*\ /g' "$OUT"
echo "Adding OT and NT markers."
sed -i'' '1i\* Old Testament' "$OUT"
sed -i'' '/^\*\* Matthew/i\* New Testament' "$OUT"
sed -i'' '1i\\' "$OUT"
echo "Adding file header."
sed -i'' '1i\#+LaTeX: \\setcounter{secnumdepth}{0}' "$OUT"
sed -i'' '1i\#+OPTIONS: author:nil date:nil toc:2' "$OUT"
sed -i'' '1i\#+STARTUP: overview' "$OUT"
sed -i'' '1i\#+SUBTITLE: King James Version (Authorized)' "$OUT"
sed -i'' '1i\#+TITLE: The Holy Bible' "$OUT"
echo "All done."

exit 0
