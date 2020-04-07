#!/bin/bash
# Script to create the PDF file for WSTG
VERSION=$1
echo "Creating PDF for version $VERSION"

# Clean the build folder
rm -rf build

# Create the required build folders
mkdir -p build/md
mkdir -p build/pdf
mkdir -p build/images

# Copy Markdown and Image files to build directory
# Replace path separators "/" with ">>>" in .md files for better splitting in later stages
find document -name "*.md" | while IFS= read -r FILE; do cp -v "$FILE" build/md/"${FILE//\//>>>}"; done
find document -name "images"  -exec cp -r {}/. build/images/. ";"
cp pdf/assets/cover.jpg build/images/book-cover.jpg

# Rename README files by prepending "0-0.0_" to keep them in the correct order
find build/md -name "*README.md" | while IFS= read -r FILE; do mv -v "$FILE" "${FILE//README/0-0.0_README}"; done

# Update build version number in pdf-config
sed -i "s/{PDF Version}/$VERSION/g" pdf/pdf-config.json

# Creating the Markdown file for the cover page
echo "<img src=\"images/book-cover.jpg\" style=\"overflow:hidden; margin-bottom:-25px; \" /><h1 style=\"position:fixed; top:52.48%; right:46.9%; color: white; border:none;font-family: 'Montserrat'; font-weight: 500;font-style: normal;\" >$VERSION</h1>" > build/cover-$VERSION.md

# Create the single document Markdown file
# Sed section 1: Add page break after each chapter
# Sed section 2: Correct Markdown file links with fragment identifiers. Remove file path and keep fragmentidentifier alone.
# Sed section 3 - 7: Replace internal Links inside headings with anchor tags inside the respective heading and link href as the heading text
# Sed section 8 - 12: Add header text as `id` element for heading to get referenced by links
# Sed section 13: Set href for internal links inside section README file. Remove subsection numbers from href.
# Sed section 14 -15: Replace the spaces inside 'id' value and `href` values with hyphen
# Sed section 16: Replace the subsection number from header text and 'id'
# Sed section 17: Add css class for image number tags
ls build/md | sort -n | while read x; do cat build/md/$x | sed -e 's/^# /<div style=\"page-break-after: always\;\"><\/div>\
\
# /' | sed 's/\[\([^\n]\+\)\]([^\n]\+.md#\([^\)]\+\)/[\1](#\2/' | sed 's/\(^#\{1\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h1><a href=\"#\4\">\4<\/a><\/h1>/'  | sed 's/\(^#\{2\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h2><a href=\"#\4\">\4<\/a><\/h2>/' | sed 's/\(^#\{3\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h3><a href=\"#\4\">\4<\/a><\/h3>/'| sed 's/\(^#\{4\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h4><a href=\"#\4\">\4<\/a><\/h4>/' | sed 's/\(^#\{5\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h5><a href=\"#\4\">\4<\/a><\/h5>/' | sed 's/\(^#\{1\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h1 id=\"\2\">\2<\/h1>/' | sed 's/\(^#\{2\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h2 id=\"\2\">\2<\/h2>/' | sed 's/\(^#\{3\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h3 id=\"\2\">\2<\/h3>/' | sed 's/\(^#\{4\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h4 id=\"\2\">\2<\/h4>/' | sed 's/\(^#\{5\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h5 id=\"\2\">\2<\/h5>/' | sed 's/\(\[\([0-9. ]*\)\(.*\)\]([0-9_.\/\-]*\(.*\).md)\(\?\:\n\+\|$\)\)/\2 <a href=\"#\3\">\3<\/a>/' | python -c "import re; import sys; print(re.sub(r'id=\"([^\n]+)\"', lambda m: m.group().replace(' ', '-'), sys.stdin.read()))"  | python -c "import re; import sys; print(re.sub(r'href=\"([^\n]+)\"', lambda m: m.group().replace(' ', '-'), sys.stdin.read()))" | sed 's/<h1 id=\"[0-9.]*-\(.*\)\">\(.*\)<\/h1>/<h1 id="\1">\2<\/h1>/' | sed 's/\*\(Figure [0-9.\-]*\: .*\)\*/<span class="image-name-tag">\1<\/span>/' >>  build/wstg-doc-$VERSION.md ; done

# Create cover page by converting Markdown to PDF
md-to-pdf  --config-file pdf/pdf-config.json  --pdf-options '{"margin":"0mm", "format": "A4"}' build/cover-$VERSION.md

# Create Document body pages by converting Markdown to PDF
md-to-pdf  --config-file pdf/pdf-config.json build/wstg-doc-$VERSION.md

# Combine Cover page and Document body
pdftk build/cover-$VERSION.pdf build/wstg-doc-$VERSION.pdf cat output build/wstg-com-$VERSION.pdf

# Create chapter wise Markdown files for generating bookmarks
# Sed sections are exactly same as lines 29-37
ls build/md | sort -n | while read x; do cat build/md/$x | sed -e 's/^# /<div style=\"page-break-after: always\;\"><\/div>\
\
# /' | sed 's/\[\([^\n]\+\)\]([^\n]\+.md#\([^\)]\+\)/[\1](#\2/' | sed 's/\(^#\{1\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h1><a href=\"#\4\">\4<\/a><\/h1>/'  | sed 's/\(^#\{2\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h2><a href=\"#\4\">\4<\/a><\/h2>/' | sed 's/\(^#\{3\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h3><a href=\"#\4\">\4<\/a><\/h3>/'| sed 's/\(^#\{4\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h4><a href=\"#\4\">\4<\/a><\/h4>/' | sed 's/\(^#\{5\} \)\(\[\([0-9. ]*\)\(.*\)\]\(.*\)\(\?\:\n\+\|$\)\)/<h5><a href=\"#\4\">\4<\/a><\/h5>/' | sed 's/\(^#\{1\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h1 id=\"\2\">\2<\/h1>/' | sed 's/\(^#\{2\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h2 id=\"\2\">\2<\/h2>/' | sed 's/\(^#\{3\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h3 id=\"\2\">\2<\/h3>/' | sed 's/\(^#\{4\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h4 id=\"\2\">\2<\/h4>/' | sed 's/\(^#\{5\} \) *\([^\n]\+\?\))*\(\?\:\n\+\|$\)/<h5 id=\"\2\">\2<\/h5>/' | sed 's/\(\[\([0-9. ]*\)\(.*\)\]([0-9_.\/\-]*\(.*\).md)\(\?\:\n\+\|$\)\)/\2 <a href=\"#\3\">\3<\/a>/' | python -c "import re; import sys; print(re.sub(r'id=\"([^\n]+)\"', lambda m: m.group().replace(' ', '-'), sys.stdin.read()))"  | python -c "import re; import sys; print(re.sub(r'href=\"([^\n]+)\"', lambda m: m.group().replace(' ', '-'), sys.stdin.read()))" | sed 's/<h1 id=\"[0-9.]*-\(.*\)\">\(.*\)<\/h1>/<h1 id="\1">\2<\/h1>/' | sed 's/\*\(Figure [0-9.\-]*\: .*\)\*/<span class="image-name-tag">\1<\/span>/'  >  build/pdf/$x ; done

# Copy images to the temporary folder to generate chapter wise PDFs
cp -r build/images build/pdf/

# Generate chapter wise PDF files
for f in build/pdf/*.md ; do md-to-pdf  --config-file pdf/pdf-config.json $f && rm $f; done

# Generate chapter details form individual chapter PDF files
# Extracts folder names and number of pages in each chapter
# Write this to chapters.txt inside build folder
for f in build/pdf/*.pdf; do IFS='>>>' read -ra FILE <<< "$f"; for i in "${FILE[@]}"; do echo $i | sed 's/build\/pdf\/document/section: /'  | sed 's/\([0-9.]\+\)-\(.*\)\.pdf/\1 \; file: \2 \;/' | sed 's/Appx\.[A-Z]_\(.*\)/6 \; sectionTitle: Appendix \;  subsection: \1 \; sectionTitle: \1 \; subsection: /' | sed 's/\([0-9.]\+\)-\(.*\)/\1 \; sectionTitle: \2 \; subsection: /' | sed 's/_/ /g' | tr -d '\n' >> build/chapters.txt; done; pdftk $f dump_data | grep NumberOfPages | awk  '{print "numberofpages: " $2 " ;"}' >>  build/chapters.txt; done;

# Generate 'bookmarks' file inside the build folder with data from chapters.txt
sectionValue="";
subsection1Value="";
subsection2Value="";
pagenumber=2;
headerlevel=0;
subsection1="";
subsection2="";
while read line; do
    IFS=';'
    read -ra entry <<< "$line";
    for i in ${entry[@]}; do
        IFS=':'
        read -r title value <<< $i
        title=$(echo $title | sed 's/ *$//g' | sed 's/^ *//g')
        value=$(echo $value | sed 's/ *$//g' | sed 's/^ *//g')

        if [ "$title" == "subsection" ]; then
            headerlevel=$(($headerlevel+1));
            if [ $headerlevel -ne 0 ]; then
                title="subsection$headerlevel";
            fi
        fi

        if [ "$title" == "sectionTitle" ]; then
            if [ $headerlevel -ne 0 ]; then
                title="sectionTitle$headerlevel";
            fi
        fi
        if [ "$title" == "file" ]; then
            headerlevel=$(($headerlevel+1));
        fi
        declare "$title=$value";
    done
    if [[ -n $sectionTitle ]]; then
        echo "BookmarkBegin" >> build/bookmarks;
        if [ "$sectionValue" != "$section" ]; then
            sectionValue=$section;
            echo "BookmarkTitle:" $section - $sectionTitle >> build/bookmarks;
            echo "BookmarkLevel: 1"  >> build/bookmarks;
        else
            if [[ -n $sectionTitle1 ]]; then
                if [ "$subsection1Value" != "$subsection1" ]; then
                    subsection1Value=$subsection1;
                    echo "BookmarkTitle:" $subsection1 - $sectionTitle1 >> build/bookmarks;
                    echo "BookmarkLevel: 2"  >> build/bookmarks;
                else
                    if [[ -n $sectionTitle2 ]]; then
                        if [ "$subsection2Value" != "$subsection2" ]; then
                            subsection2Value=$subsection2;
                            echo "BookmarkTitle:" $subsection2 - $sectionTitle2 >> build/bookmarks;
                        else
                            if [ "$file" == "0.0 README" ] ; then
                                echo "BookmarkTitle:" $subsection2 - $sectionTitle2 >> build/bookmarks;
                            else
                                echo "BookmarkTitle:" $subsection2 - $file >> build/bookmarks;
                            fi
                        fi
                    else
                        if [ "$file" == "0.0 README" ] ; then
                            echo "BookmarkTitle:" $subsection2 - sectionTitle1 >> build/bookmarks;
                        else
                            echo "BookmarkTitle:" $subsection2 - $file >> build/bookmarks;
                        fi
                    fi
                    echo "BookmarkLevel: 3" >> build/bookmarks;
                fi
            else
                if [ "$file" == "0.0 README" ] ; then
                    echo "BookmarkTitle:" $subsection1 - $sectionTitle >> build/bookmarks;
                else
                    echo "BookmarkTitle:" $subsection1 - $file >> build/bookmarks;
                fi
                echo "BookmarkLevel: 2"  >> build/bookmarks;
            fi
        fi
        echo "BookmarkPageNumber:" $pagenumber >> build/bookmarks;
    fi
    pagenumber=$(($pagenumber+$numberofpages));
    numberofpages=0;
    headerlevel=0;

done < build/chapters.txt;


# Dumping PDF metadata from already created PDF to pdf_data file inside the build folder
pdftk build/wstg-com-$VERSION.pdf dump_data_utf8 output build/pdf_data

# Clear dumped pdf_data file of any previous bookmarks
sed -i '/Bookmark/d' build/pdf_data

# Inserting previously created bookmarks in to the pdf_data file
sed -i "/NumberOfPages/r build/bookmarks" build/pdf_data

# Create the final pdf by inserting the metadata from pdf_data file
pdftk build/wstg-com-$VERSION.pdf update_info_utf8 build/pdf_data output build/wstg-$VERSION.pdf