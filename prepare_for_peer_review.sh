#/bim/bash

# Reading Config
echo "Reading config...."
source settings/config

# Clear output
rm "$OUTPUT_DIR"/* -r
# Manuscript

for file in "$INPUT_DIR"/"$MANUSCRIPT_PREFIX"*
do
if [ -f "$file" ] ; then
 echo "Processing $file"
 basename=$( echo $(basename "$file") |  sed 's/[^A-Za-z0-9_.]/-/g;s/-*-/-/g;s/^-//;s/-$//;s/-\././g' )
 mainfile="$OUTPUT_DIR/$basename-all.md"
 mdfile="$OUTPUT_DIR/${basename%.*}.md"
 outfile="$OUTPUT_DIR/${basename%.*}.pdf"
 if [[ $(xdg-mime query filetype "$file") == application\/msword ]]
 then
   echo "converting to docx"
   unoconv -f docx -o "$OUTPUT_DIR/${basename%.*}.docx" "$file"
   file="$OUTPUT_DIR/${basename%.*}.docx"
 fi
 touch "$mdfile"
 printf "## Manuscript\n\n" > "$mdfile"
# echo "$(pandoc -t markdown ""$file"" --extract-media=img)" >> "$mdfile"
 pandoc -t markdown "$file" --extract-media=img >> "$mdfile"
 cat "$mdfile" > "$mainfile"
 echo "$mainfile"
 pandoc "$mdfile" -o "$outfile" --latex-engine=xelatex -H $SETTINGS_DIR/options.sty
fi
done

# Captions
for file in "$INPUT_DIR"/"$CAPTION_PREFIX"*
do
 if [ -f "$file" ] ; then
 echo "Processing $file"
 basename=$( echo $(basename "$file") |  sed 's/[^A-Za-z0-9_.]/-/g;s/-*-/-/g;s/^-//;s/-$//;s/-\././g' )
 mdfile="$OUTPUT_DIR/${basename%.*}.md"
 outfile="$OUTPUT_DIR/${basename%.*}.pdf"
 if [[ $(xdg-mime query filetype "$file") == application\/msword ]]
 then
   echo "converting to docx"
   unoconv -f docx -o "$OUTPUT_DIR/${basename%.*}.docx" "$file"
   file="$OUTPUT_DIR/${basename%.*}.docx"
 fi
 touch "$mdfile"
 printf "\n\n\pagebreak\n\n## Captions\n\n" > "$mdfile"
 printf "$(pandoc -t markdown ""$file"")" >> "$mdfile"
 pandoc "$mdfile" -o "$outfile" --latex-engine=xelatex -H $SETTINGS_DIR/options_pn.sty
 cat "$mdfile" >> "$mainfile"
fi
done

# Tables
COUNTER=0
for file in "$INPUT_DIR"/"$TABLES_PREFIX"*
do
 if [ -f "$file" ] ; then
 let COUNTER=COUNTER+1 
 echo "Processing $file"
 basename=$( echo $(basename "$file") |  sed 's/[^A-Za-z0-9_.]/-/g;s/-*-/-/g;s/^-//;s/-$//;s/-\././g' )
 htmlfile="$OUTPUT_DIR/${basename%.*}.html"
 outfile_pdf="$OUTPUT_DIR/${basename%.*}.pdf"
# printf "\n\pagebreak\n\n# Table $((i+1))\n\n" > $outfile
 if [[ $(xdg-mime query filetype "$file") == application\/msword ]]
 then
   echo "converting to docx"
   unoconv -f docx -o "$OUTPUT_DIR/${basename%.*}.docx" "$file"
   file="$OUTPUT_DIR/${basename%.*}.docx"
 fi
 pandoc "$file" -o "$htmlfile"
 pandoc "$htmlfile" -o "$outfile_pdf" --latex-engine=xelatex -H "$SETTINGS_DIR"/options_table.sty
 outfile_md="$OUTPUT_DIR/${basename%.*}.md"
 touch "$outfile_md"
 printf "\n\n\pagebreak\n\n## Table  $COUNTER: ${basename:5}\n\n" > "$outfile_md"
 mkdir "$outfile_pdf.dir"
 pdftk "$outfile_pdf" burst output "$outfile_pdf.dir/page_%03d.pdf"
 rm "$outfile_pdf.dir/doc_data.txt"
 for file in "$outfile_pdf.dir"/*
 do
  printf "![$basename]($file)\ \n\n\pagebreak" >> "$outfile_md"
 done
 cat "$outfile_md" >> "$mainfile"
fi
done

# Figures
COUNTER=0
for file in "$INPUT_DIR"/"$FIGURE_PREFIX"*
do
if [ -f "$file" ] ; then
 let COUNTER=COUNTER+1
 echo "Processing $file"
 basename=$( echo $(basename "$file") |  sed 's/[^A-Za-z0-9_.]/-/g;s/-*-/-/g;s/^-//;s/-$//;s/-\././g' )
 this_fig_nr=$(echo "$basename" | cut -c3-4)
 outfile_img="$OUTPUT_DIR/${basename%.*}.pdf"
 this_filetype=$(xdg-mime query filetype "$file")
 if [[ " ${VECTORFORMATS[@]} " =~ " ${this_filetype} " ]]; then
  if [[ $this_filetype == image\/x-eps ]]; then
    ps2pdf -r150 -dPDFSETTINGS=/screen -dEPSCrop "$file" $outfile_img
  else
    convert "$file" $outfile_img
 fi
 else
 $(convert -strip -interlace Plane -gaussian-blur 0.05 -quality 85% -units PixelsPerInch "$file" -compress jpeg -resize 1753x1240 -units PixelsPerInch -density 150 $outfile_img)
 fi
 outfile_md="$OUTPUT_DIR/${basename%.*}.md"
 touch $outfile_md
 if [ "$this_fig_nr" != "$last_fig_nr" ]; then 
   printf "\n\n\pagebreak\n\n## Figure $this_fig_nr: ${basename:5}" > "$outfile_md"
 fi
 printf "\n\n![$basename]($outfile_img)\ " >> "$outfile_md"
 cat "$outfile_md" >> "$mainfile"
 last_fig_nr=$this_fig_nr
fi
done

# re-pdf
#pandoc $mainfile -o $OUTPUT_DIR/$(basename $mainfile).pdf --latex-engine=xelatex -H $SETTINGS_DIR/options.sty 
pandoc "$mainfile" -o "$FINAL_OUTPUT_DIR"/review_pdf.pdf --latex-engine=xelatex -H $SETTINGS_DIR/options_pn.sty 
tar -cf "$FINAL_OUTPUT_DIR"/output_archiv.tar "$OUTPUT_DIR"/ 
