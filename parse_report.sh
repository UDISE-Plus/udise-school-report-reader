#!/bin/bash
echo "Processing PDF file: $1"
# Delete existing YAML output if it exists
yml_file="${1%.*}.yml"
rm ./carmel-2223/carmel-2223.yml
rm ./carmel-2223/carmel-2223_enrollment.html
ruby -r "./school_report_parser.rb" -e "SchoolReportParser.extract_to_text('./carmel-2223/carmel-2223.pdf')"

rm ./sarvo-2223/sarvo-2223.yml
rm ./sarvo-2223/sarvo-2223_enrollment.html
ruby -r "./school_report_parser.rb" -e "SchoolReportParser.extract_to_text('./sarvo-2223/sarvo-2223.pdf')"

rm ./jhita-2223/jhita-2223.yml
rm ./jhita-2223/jhita-2223_enrollment.html
ruby -r "./school_report_parser.rb" -e "SchoolReportParser.extract_to_text('./jhita-2223/jhita-2223.pdf')"

echo "Done! Check the output files in the same directory as the PDF." 
