#!/bin/bash
echo "Processing PDF file: $1"
ruby -r "./school_report_parser.rb" -e "SchoolReportParser.extract_to_text('$1')"
echo "Done! Check the output files in the same directory as the PDF." 