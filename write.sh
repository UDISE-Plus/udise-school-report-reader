#!/bin/bash

# Make script exit on any error
set -e

# Add the lib directory to Ruby's load path
export RUBYLIB="./lib:$RUBYLIB"

for school in carmel-2223 sarvo-2223 jhita-2223 kachora-2223; do
  echo "Processing PDF file: ./samples/$school/$school.pdf"
  echo "  - Cleaning up old files..."
  rm -f "./samples/$school/$school.yml"
  
  echo "  - Extracting data from PDF..."
  ruby -r "udise_school_report_reader" -e "UdiseSchoolReportReader::SchoolReportParser.extract_to_text('./samples/$school/$school.pdf', nil, true)"
  
  echo "  - Completed processing $school"
done

echo "Done! Check the output files in the samples directory." 
