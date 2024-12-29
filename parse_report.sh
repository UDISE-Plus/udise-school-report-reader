#!/bin/bash
echo "Processing PDF file: $1"
# Delete existing YAML output if it exists
yml_file="${1%.*}.yml"
if [ -f "$yml_file" ]; then
    echo "Removing existing YAML file: $yml_file"
    rm "$yml_file"
fi
ruby -r "./school_report_parser.rb" -e "SchoolReportParser.extract_to_text('$1')"
echo "Done! Check the output files in the same directory as the PDF." 