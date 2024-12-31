#!/bin/bash
echo "Processing PDF file: $1"
# Delete existing YAML output if it exists
yml_file="${1%.*}.yml"
for dir in carmel-2223 sarvo-2223 jhita-2223 kachora-2223; do
  rm ./$dir/$dir.yml
  rm ./$dir/${dir}_enrollment.html
  ruby -r "./school_report_parser.rb" -e "SchoolReportParser.extract_to_text('./$dir/$dir.pdf')"
done

echo "Done! Check the output files in the same directory as the PDF." 
