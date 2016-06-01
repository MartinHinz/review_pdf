#/bim/bash

MANUSCRIPT_PREFIX='a-'
CAPTION_PREFIX='b-'
TABLES_PREFIX='c-'
FIGURE_PREFIX='d-'

INPUT_DIR='input'
OUTPUT_DIR='output'
SETTINGS_DIR='settings'
FINAL_OUTPUT_DIR='final_output'

# Clear output
rm $OUTPUT_DIR/* -r
# Manuscript

for file in $INPUT_DIR/$MANUSCRIPT_PREFIX*
do
 echo "Processing $file"
 basename=$(basename $file)
 mainfile=$OUTPUT_DIR/$basename-all.md
 mdfile="$OUTPUT_DIR/${basename%.*}.md"
 outfile="$OUTPUT_DIR/${basename%.*}.pdf"
 touch $mdfile
 printf "## Manuscript\n\n" > $mdfile
 echo "$(pandoc -t markdown ""$file"")" >> $mdfile
 cat $mdfile > $mainfile
 pandoc "$mdfile" -o "$outfile" --latex-engine=xelatex -H $SETTINGS_DIR/options.sty
done

# Captions

for file in $INPUT_DIR/$CAPTION_PREFIX*
do
 echo "Processing $file"
 basename=$(basename $file)
 mdfile="$OUTPUT_DIR/${basename%.*}.md"
 outfile="$OUTPUT_DIR/${basename%.*}.pdf"
 touch $mdfile
 printf "\n\n\pagebreak\n\n## Captions\n\n" > $mdfile
 printf "$(pandoc -t markdown ""$file"")" >> $mdfile
 pandoc "$mdfile" -o "$outfile" --latex-engine=xelatex -H $SETTINGS_DIR/options_pn.sty
 cat $mdfile >> $mainfile
done

# Tables
COUNTER=0
for file in "$INPUT_DIR"/"$TABLES_PREFIX"*
do
 let COUNTER=COUNTER+1 
 echo "Processing $file"
 basename=$(basename $file)
 htmlfile="$OUTPUT_DIR/${basename%.*}.html"
 outfile_pdf="$OUTPUT_DIR/${basename%.*}.pdf"
# printf "\n\pagebreak\n\n# Table $((i+1))\n\n" > $outfile
 pandoc "$file" -o "$htmlfile"
 pandoc "$htmlfile" -o "$outfile_pdf" --latex-engine=xelatex -H $SETTINGS_DIR/options_table.sty
 outfile_md="$OUTPUT_DIR/${basename%.*}.md"
 touch $outfile_md
 printf "\n\n\pagebreak\n\n## Table  $COUNTER: ${basename:5}\n\n" > $outfile_md
 mkdir $outfile_pdf.dir
 pdftk $outfile_pdf burst output $outfile_pdf.dir/page_%03d.pdf
 rm $outfile_pdf.dir/doc_data.txt
 for file in $outfile_pdf.dir/*
 do
  printf "![$basename]($file)\ \n\n\pagebreak" >> $outfile_md 
 done
 cat $outfile_md >> $mainfile
done

# Figures
COUNTER=0
for file in "$INPUT_DIR"/"$FIGURE_PREFIX"*
do
 let COUNTER=COUNTER+1 
 echo "Processing $file"
 basename=$(basename $file)
 outfile_img="$OUTPUT_DIR/${basename%.*}.pdf"
 $(convert $file $outfile_img)
 outfile_md="$OUTPUT_DIR/${basename%.*}.md"
 touch $outfile_md
 printf "\n\n\pagebreak\n\n## Figure $COUNTER: ${basename:5}\n\n" > $outfile_md
 printf "![$basename]($outfile_img)\ " >> $outfile_md
 cat $outfile_md >> $mainfile
done

# re-pdf
#pandoc $mainfile -o $OUTPUT_DIR/$(basename $mainfile).pdf --latex-engine=xelatex -H $SETTINGS_DIR/options.sty 
pandoc $mainfile -o "$FINAL_OUTPUT_DIR"/review_pdf.pdf --latex-engine=xelatex -H $SETTINGS_DIR/options_pn.sty 
tar -cf "$FINAL_OUTPUT_DIR"/output_archiv.tar "$OUTPUT_DIR"/ 
