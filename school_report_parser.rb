class SchoolReportParser
  require 'pdf-reader'
  require 'yaml'

  def self.extract_to_text(pdf_path)
    raise ArgumentError, "PDF file not found" unless File.exist?(pdf_path)
    
    reader = PDF::Reader.new(pdf_path)
    content = reader.pages.map(&:raw_content).join("\n")
    
    # Create text file with same name as PDF
    txt_path = pdf_path.sub(/\.pdf$/i, '.txt')
    File.write(txt_path, content)
    
    # Create compressed version
    compressed_content = compress_content(content)
    compressed_path = pdf_path.sub(/\.pdf$/i, '_compressed.txt')
    File.write(compressed_path, compressed_content)
    
    # Extract data points to YAML
    data_points = extract_data_points(compressed_content)
    yaml_path = pdf_path.sub(/\.pdf$/i, '.yml')
    File.write(yaml_path, data_points.to_yaml)
    
    [txt_path, compressed_path, yaml_path]
  end

  private

  def self.compress_content(content)
    compressed = []
    current_block = []
    in_bt_block = false

    content.each_line do |line|
      if line.include?('BT')
        in_bt_block = true
        current_block = []
      elsif line.include?('ET')
        in_bt_block = false
        block_text = current_block.reject(&:empty?).join("\n")
        compressed << block_text unless block_text.empty?
      elsif in_bt_block && line =~ /\((.*?)\)\s*Tj/
        # Extract text between (...) followed by Tj
        text = $1.strip
        current_block << text unless text.empty?
      end
    end

    compressed.reject(&:empty?).join("\n")
  end

  def self.extract_data_points(compressed_content)
    data = {
      'basic_info' => {},
      'location' => {},
      'school_details' => {},
      'infrastructure' => {
        'toilets' => {},
        'classrooms' => {},
        'digital_facilities' => {},
        'other_facilities' => {}
      },
      'teachers' => {
        'count_by_level' => {},
        'qualifications' => {},
        'demographics' => {}
      },
      'students' => {},
      'academic' => {
        'medium_of_instruction' => {},
        'inspections' => {}
      }
    }

    lines = compressed_content.split("\n")
    current_section = nil
    current_subsection = nil

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]
      prev_line = lines[i - 1] if i > 0

      case line.strip
      # Basic Info
      when "UDISE CODE"
        if next_line && (match = next_line.match(/(\d{2})\s*(\d{2})\s*(\d{2})\s*(\d{2})\s*(\d{3})/))
          data['basic_info']['udise_code'] = match[1..5].join('')
        end
      when "School Name"
        if next_line && next_line.include?("CARMEL")
          data['basic_info']['name'] = next_line
        end
      
      # Location
      when "State"
        data['location']['state'] = next_line if next_line
      when "District"
        data['location']['district'] = next_line if next_line
      when "Block"
        data['location']['block'] = next_line if next_line
      when "Rural / Urban"
        data['location']['area_type'] = next_line if next_line
      when "Pincode"
        data['location']['pincode'] = next_line if next_line
      when "Ward"
        data['location']['ward'] = next_line if next_line
      
      # School Details
      when "School Category"
        data['school_details']['category'] = next_line if next_line
      when "School Management"
        data['school_details']['management'] = next_line if next_line
      when "School Type"
        data['school_details']['type'] = next_line if next_line
      when "Year of Establishment"
        data['school_details']['established'] = next_line.to_i if next_line
      when "Building Status"
        data['school_details']['building_status'] = next_line if next_line
      
      # Infrastructure
      when "Toilets"
        current_section = 'toilets'
      when /^Total\(Excluding CWSN\)$/ && current_section == 'toilets'
        if next_line && next_line.match?(/^\d+$/)
          data['infrastructure']['toilets']['boys'] = next_line.to_i
          data['infrastructure']['toilets']['girls'] = lines[i + 2].to_i if lines[i + 2]
        end
      when /^Functional$/ && current_section == 'toilets'
        if next_line && next_line.match?(/^\d+$/)
          data['infrastructure']['toilets']['functional_boys'] = next_line.to_i
          data['infrastructure']['toilets']['functional_girls'] = lines[i + 2].to_i if lines[i + 2]
        end
      
      # Classrooms
      when "Total Class Rooms"
        if next_line && next_line.match?(/^\d+$/)
          data['infrastructure']['classrooms']['total'] = next_line.to_i
        end
      when "In Good Condition"
        if next_line && next_line.match?(/^\d+$/)
          data['infrastructure']['classrooms']['good_condition'] = next_line.to_i
        end
      
      # Digital Facilities
      when "Digital Facilities (Functional)"
        current_section = 'digital'
      when "ICT Lab" && current_section == 'digital'
        data['infrastructure']['digital_facilities']['ict_lab'] = next_line if next_line
      when "Desktop" && current_section == 'digital'
        data['infrastructure']['digital_facilities']['desktop'] = next_line.to_i if next_line
      when "Internet" && current_section == 'digital'
        data['infrastructure']['digital_facilities']['internet'] = next_line if next_line
      
      # Academic
      when /^Medium (\d)$/
        if next_line
          data['academic']['medium_of_instruction']["medium_#{$1}"] = next_line
        end
      
      # Teachers
      when "Nature of Appointment"
        current_section = 'teachers'
      when "Regular" && current_section == 'teachers'
        data['teachers']['count_by_level']['regular'] = next_line.to_i if next_line
      when "Gender"
        if lines[i + 1] && lines[i + 2] && lines[i + 3]
          data['teachers']['demographics']['male'] = lines[i + 1].to_i
          data['teachers']['demographics']['female'] = lines[i + 2].to_i
          data['teachers']['demographics']['transgender'] = lines[i + 3].to_i
        end
      end
    end

    # Clean up empty sections
    data.each do |_, section|
      if section.is_a?(Hash)
        section.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
      end
    end
    data.reject! { |_, v| v.empty? }
    
    data
  end
end