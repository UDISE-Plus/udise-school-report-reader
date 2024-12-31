#!/bin/bash
for dir in carmel-2223 sarvo-2223 jhita-2223 kachora-2223; do
  echo "Processing PDF file: ./samples/$dir/$dir.pdf"
  echo "  - Cleaning up old files..."
  rm -f ./samples/$dir/$dir.yml
  rm -f ./samples/$dir/${dir}_enrollment.html
  echo "  - Extracting data from PDF..."
  ruby -r "./school_report_parser.rb" -e "SchoolReportParser.extract_to_text('./samples/$dir/$dir.pdf')"
  echo "  - Completed processing $dir"
done
echo "Done! Check the output files in the samples directory." 
