require 'yaml'
require 'nokogiri'    # For parsing text content
require 'pdf-reader'  # For reading PDF files

class SchoolReportParser
  def initialize(pdf_path)
    @pdf_path = pdf_path
    @text = ''
    @data = {
      'school_info' => {},
      'infrastructure' => {},
      'enrollment' => {
        'by_category' => {},
        'by_age' => {}
      },
      'teachers' => {},
      'facilities' => {}
    }
  end

  def extract_text
    reader = PDF::Reader.new(@pdf_path)
    @text = reader.pages.map(&:text).join("\n")
    
    # Write text content to a file in the same directory as the PDF
    output_dir = File.dirname(@pdf_path)
    text_file = File.join(output_dir, "#{File.basename(@pdf_path, '.*')}_text_rb.txt")
    File.write(text_file, @text)
    puts "Text content written to: #{text_file}"
    
    # Write raw content to a file
    raw_content = reader.pages.map(&:raw_content).join("\n")
    raw_file = File.join(output_dir, "#{File.basename(@pdf_path, '.*')}_raw_rb.txt")
    File.write(raw_file, raw_content)
    puts "Raw content written to: #{raw_file}"
    
    # Keep the debug output
    puts "\nDEBUG Text Content:"
    puts "=== Basic Info Section ==="
    puts @text.match(/UDISE.*?Constituency/m)&.to_s
    puts "\n=== Municipality Section ==="
    puts @text.match(/Panchayat.*?Assembly/m)&.to_s
    puts "\n---"
  end

  def extract_value(pattern)
    match = @text.match(pattern)
    match ? match[1].strip : nil
  end

  def parse_basic_info
    @data['school_info'] = {
      'udise_code' => extract_value(/UDISE\s*CODE\s+(\d+\s+\d+\s+\d+\s+\d+\s+\d+)/i),
      'school_name' => extract_value(/School\s*Name\s+(.*?)(?=\s+State|$)/i),
      'state' => extract_value(/State\s+(.*?)(?=\s+District)/i),
      'district' => extract_value(/District\s+(.*?)(?=\s+Block)/i),
      'block' => extract_value(/Block\s+(.*?)(?=\s*$|\n)/i),
      'rural_urban' => extract_value(/Rural\s*\/\s*Urban\s+([\w\-]+)/i),
      'cluster' => extract_value(/Cluster\s+(.*?)(?=\s+Ward|$)/i),
      'ward' => extract_value(/Ward\s+(.*?)(?=\s+Mohalla)/i),
      'mohalla' => extract_value(/Mohalla\s+(.*?)(?=\s+Pincode)/i),
      'pincode' => extract_value(/Pincode\s+(\d{6})/i),
      'panchayat' => extract_value(/Panchayat\s+(.*?)(?=\s+City)/i),
      'city' => extract_value(/City\s+(.+?)(?=\s+Municipality)/m),
      'municipality' => extract_value(/Municipality\s+(.*?)(?=\s+Assembly Const\.|$)/i),
      'assembly_constituency' => extract_value(/Assembly Const\.\s+(.*?)(?=\s+Parl\. Constituency|$)/i),
      'parliamentary_constituency' => extract_value(/Parl\.\s+Constituency\s+(.*?)(?=\s+School Category|$)/i)
    }
    
    # Clean up extracted values
    @data['school_info'].each do |key, value|
      if value.is_a?(String)
        value = value.gsub(/\s+/, ' ').strip
        @data['school_info'][key] = value.empty? || value.upcase == 'NA' ? nil : value
      end
    end
  end

  def parse_infrastructure
    @data['infrastructure'] = {
      'building_status' => extract_value(/Building Status[:\s]+([^\n]+)/i),
      'boundary_wall' => extract_value(/Boundary Wall[:\s]+([^\n]+)/i),
      'building_blocks' => extract_value(/Building Blocks[:\s]+(\d+)/i)&.to_i,
      'total_classrooms' => extract_value(/Total Classrooms[:\s]+(\d+)/i)&.to_i,
      'classrooms_good_condition' => extract_value(/Classrooms in Good Condition[:\s]+(\d+)/i)&.to_i,
      'needs_major_repair' => extract_value(/Needs Major Repair[:\s]+(\d+)/i)&.to_i,
      'other_rooms' => extract_value(/Other Rooms[:\s]+(\d+)/i)&.to_i,
      'toilets' => parse_toilets
    }
  end

  def parse_toilets
    {
      'boys' => {
        'total' => extract_value(/Boys Toilets Total[:\s]+(\d+)/i)&.to_i,
        'functional' => extract_value(/Boys Toilets Functional[:\s]+(\d+)/i)&.to_i,
        'cwsn_friendly' => extract_value(/Boys CWSN Friendly[:\s]+(\d+)/i)&.to_i,
        'urinal' => extract_value(/Boys Urinals[:\s]+(\d+)/i)&.to_i
      },
      'girls' => {
        'total' => extract_value(/Girls Toilets Total[:\s]+(\d+)/i)&.to_i,
        'functional' => extract_value(/Girls Toilets Functional[:\s]+(\d+)/i)&.to_i,
        'cwsn_friendly' => extract_value(/Girls CWSN Friendly[:\s]+(\d+)/i)&.to_i,
        'urinal' => extract_value(/Girls Urinals[:\s]+(\d+)/i)&.to_i
      }
    }
  end

  def parse_facilities
    @data['facilities'] = {
      'digital' => parse_digital_facilities,
      'basic_amenities' => parse_basic_amenities
    }
  end

  def parse_digital_facilities
    {
      'ict_lab' => extract_value(/ICT Lab[:\s]+(Yes|No)/i)&.downcase == 'yes',
      'internet' => extract_value(/Internet[:\s]+(Yes|No)/i)&.downcase == 'yes',
      'desktop_count' => extract_value(/Desktop Computers[:\s]+(\d+)/i)&.to_i,
      'tablet_count' => extract_value(/Tablets[:\s]+(\d+)/i)&.to_i,
      'projector_count' => extract_value(/Projectors[:\s]+(\d+)/i)&.to_i,
      'digiboard_count' => extract_value(/Digital Boards[:\s]+(\d+)/i)&.to_i
    }
  end

  def parse_basic_amenities
    {
      'drinking_water_available' => extract_value(/Drinking Water Available[:\s]+(Yes|No)/i)&.downcase == 'yes',
      'drinking_water_functional' => extract_value(/Drinking Water Functional[:\s]+(Yes|No)/i)&.downcase == 'yes',
      'rain_water_harvesting' => extract_value(/Rain Water Harvesting[:\s]+(Yes|No)/i)&.downcase == 'yes',
      'playground_available' => extract_value(/Playground[:\s]+(Yes|No)/i)&.downcase == 'yes',
      'electricity_available' => extract_value(/Electricity[:\s]+(Yes|No)/i)&.downcase == 'yes',
      'solar_panel' => extract_value(/Solar Panel[:\s]+(Yes|No)/i)&.downcase == 'yes',
      'medical_checkups' => extract_value(/Medical Checkups[:\s]+(Yes|No)/i)&.downcase == 'yes'
    }
  end

  def parse_enrollment
    @data['enrollment']['total'] = {
      'boys' => extract_value(/Total Boys Enrolled[:\s]+(\d+)/i)&.to_i || 0,
      'girls' => extract_value(/Total Girls Enrolled[:\s]+(\d+)/i)&.to_i || 0
    }
    
    # Add nil check when calculating total
    @data['enrollment']['total']['total'] = (
      @data['enrollment']['total']['boys'] || 0
    ) + (
      @data['enrollment']['total']['girls'] || 0
    )

    parse_category_enrollment
  end

  def parse_category_enrollment
    categories = {
      'general' => /General Category[:\s]+Boys[:\s]+(\d+).*Girls[:\s]+(\d+)/im,
      'sc' => /SC Category[:\s]+Boys[:\s]+(\d+).*Girls[:\s]+(\d+)/im,
      'st' => /ST Category[:\s]+Boys[:\s]+(\d+).*Girls[:\s]+(\d+)/im,
      'obc' => /OBC Category[:\s]+Boys[:\s]+(\d+).*Girls[:\s]+(\d+)/im
    }

    @data['enrollment']['by_category'] = {}
    
    categories.each do |category, pattern|
      if match = @text.match(pattern)
        boys = match[1]&.to_i || 0
        girls = match[2]&.to_i || 0
        @data['enrollment']['by_category'][category] = {
          'boys' => boys,
          'girls' => girls,
          'total' => boys + girls
        }
      end
    end
  end

  def generate_report
    extract_text
    parse_basic_info
    parse_infrastructure
    parse_facilities
    parse_enrollment
    
    # Get the directory of the input PDF
    output_dir = File.dirname(@pdf_path)
    # Create output filename in the same directory
    output_file = File.join(output_dir, "#{File.basename(@pdf_path, '.*')}_report_rb.yml")
    
    # Use YAML.dump instead of to_yaml to avoid Ruby-specific type indicators
    File.write(output_file, YAML.dump(@data))
    puts "Report generated: #{output_file}"
  end
end

# Check if PDF file is provided as argument
if ARGV.empty?
  puts "Usage: ruby #{__FILE__} path/to/school_report.pdf"
  exit 1
end

# Create and run the parser
begin
  pdf_path = ARGV[0]
  
  # Check if file exists
  unless File.exist?(pdf_path)
    puts "Error: PDF file '#{pdf_path}' not found"
    exit 1
  end
  
  # Check if it's actually a PDF file
  unless File.extname(pdf_path).downcase == '.pdf'
    puts "Error: File '#{pdf_path}' is not a PDF file"
    exit 1
  end
  
  parser = SchoolReportParser.new(pdf_path)
  parser.generate_report
rescue PDF::Reader::MalformedPDFError => e
  puts "Error: The PDF file appears to be corrupted or invalid"
  puts e.message
  exit 1
rescue => e
  puts "Error: #{e.message}"
  exit 1
end