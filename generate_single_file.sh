#!/bin/sh

OUT="KJV.org"

echo "Removing any old KJV.org file."
if [ -f "$OUT" ]; then
    rm "$OUT" || exit 1
fi

echo "Combining all source files."
for file in *.org; do
    if [ ! "$file" = "README.org" ]; then
        cat "$file" >> "$OUT"
        echo "" >> "$OUT"
    fi
done

echo "Moving all chapter markers one step to the right."
sed -i'' 's/^\*\ /\*\*\ /g' "$OUT"
echo "Converting TITLEs to headers."
sed -i'' 's/^#+TITLE\:\ /\*\ /g' "$OUT"
sed -i'' '1i\\' "$OUT"
sed -i'' '1i\#+STARTUP: overview' "$OUT"
sed -i'' '1i\#+SUBTITLE: King James Version (Authorized)' "$OUT"
sed -i'' '1i\#+TITLE: The Holy Bible' "$OUT"
echo "All done."

exit 0
