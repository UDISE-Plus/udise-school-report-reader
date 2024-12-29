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
        'other_facilities' => {},
        'building' => {}
      },
      'teachers' => {
        'count_by_level' => {},
        'qualifications' => {},
        'demographics' => {},
        'training' => {}
      },
      'students' => {
        'enrollment' => {},
        'facilities' => {}
      },
      'academic' => {
        'medium_of_instruction' => {},
        'inspections' => {},
        'hours' => {}
      },
      'facilities' => {
        'residential' => {},
        'basic' => {}
      }
    }

    lines = compressed_content.split("\n").map(&:strip)
    current_section = nil
    current_subsection = nil
    in_toilet_section = false
    in_digital_section = false
    in_teacher_section = false
    in_medium_section = false

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip
      next_next_line = lines[i + 2]&.strip
      prev_line = lines[i - 1]&.strip if i > 0

      case line
      # Basic Info
      when "UDISE CODE"
        if next_line && (match = next_line.match(/(\d{2})\s*(\d{2})\s*(\d{2})\s*(\d{2})\s*(\d{3})/))
          data['basic_info']['udise_code'] = match[1..5].join('')
        end
      when "School Name"
        if next_line && next_line.include?("CARMEL")
          data['basic_info']['name'] = next_line
        end
      when "Academic Year"
        if next_line && next_line.match?(/\d{4}-\d{2}/)
          data['basic_info']['academic_year'] = next_line
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
      when "Cluster"
        data['location']['cluster'] = next_line if next_line
      when "Municipality"
        data['location']['municipality'] = next_line if next_line
      
      # School Details
      when "School Category"
        data['school_details']['category'] = next_line if next_line
      when "School Management"
        data['school_details']['management'] = next_line if next_line
      when "School Type"
        data['school_details']['type'] = next_line if next_line
      when "Lowest & Highest Class"
        data['school_details']['class_range'] = next_line if next_line
      when "Pre Primary"
        data['school_details']['pre_primary'] = next_line if next_line
      when "Year of Establishment"
        data['school_details']['established'] = next_line.to_i if next_line
      when "Building Status"
        data['school_details']['building_status'] = next_line if next_line
      when "Boundary wall"
        data['infrastructure']['building']['boundary_wall'] = next_line if next_line
      when "No.of Building Blocks"
        data['infrastructure']['building']['blocks'] = next_line.to_i if next_line =~ /^\d+$/
      
      # Infrastructure - Toilets
      when "Toilets"
        in_toilet_section = true
        current_section = 'toilets'
      when "Total(Excluding CWSN)" && in_toilet_section
        if next_line =~ /^\d+$/ && next_next_line =~ /^\d+$/
          data['infrastructure']['toilets']['boys'] = next_line.to_i
          data['infrastructure']['toilets']['girls'] = next_next_line.to_i
        end
      when "Functional" && in_toilet_section
        if next_line =~ /^\d+$/ && next_next_line =~ /^\d+$/
          data['infrastructure']['toilets']['functional_boys'] = next_line.to_i
          data['infrastructure']['toilets']['functional_girls'] = next_next_line.to_i
        end
      when "Func. CWSN Friendly" && in_toilet_section
        if next_line =~ /^\d+$/ && next_next_line =~ /^\d+$/
          data['infrastructure']['toilets']['cwsn_boys'] = next_line.to_i
          data['infrastructure']['toilets']['cwsn_girls'] = next_next_line.to_i
        end
      when "Urinal" && in_toilet_section
        if next_line =~ /^\d+$/ && next_next_line =~ /^\d+$/
          data['infrastructure']['toilets']['urinal_boys'] = next_line.to_i
          data['infrastructure']['toilets']['urinal_girls'] = next_next_line.to_i
        end
      
      # Basic Facilities
      when "Handwash Near Toilet"
        data['facilities']['basic']['handwash_near_toilet'] = next_line if next_line
      when "Handwash Facility for Meal"
        data['facilities']['basic']['handwash_for_meal'] = next_line if next_line
      when "Drinking Water Available"
        data['facilities']['basic']['drinking_water'] = next_line if next_line
      when "Drinking Water Functional"
        data['facilities']['basic']['drinking_water_functional'] = next_line if next_line
      when "Rain Water Harvesting"
        data['facilities']['basic']['rain_water_harvesting'] = next_line if next_line
      when "Playground Available"
        data['facilities']['basic']['playground'] = next_line if next_line
      when "Electricity Availability"
        data['facilities']['basic']['electricity'] = next_line if next_line
      when "Solar Panel"
        data['facilities']['basic']['solar_panel'] = next_line if next_line
      when "Library Availability"
        data['facilities']['basic']['library'] = next_line if next_line
      
      # Infrastructure - Classrooms
      when "Total Class Rooms"
        in_toilet_section = false
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['total'] = next_line.to_i
        end
      when "In Good Condition"
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['good_condition'] = next_line.to_i
        end
      when "Needs Minor Repair"
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['needs_minor_repair'] = next_line.to_i
        end
      when "Needs Major Repair"
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['needs_major_repair'] = next_line.to_i
        end
      when "Other Rooms"
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['other_rooms'] = next_line.to_i
        end
      
      # Digital Facilities
      when "Digital Facilities (Functional)"
        in_digital_section = true
        in_toilet_section = false
      when "ICT Lab" && in_digital_section
        data['infrastructure']['digital_facilities']['ict_lab'] = next_line
      when "Internet" && in_digital_section
        data['infrastructure']['digital_facilities']['internet'] = next_line
      when "Desktop" && in_digital_section
        data['infrastructure']['digital_facilities']['desktop'] = next_line.to_i if next_line =~ /^\d+$/
      when "Laptop" && in_digital_section
        data['infrastructure']['digital_facilities']['laptop'] = next_line.to_i if next_line =~ /^\d+$/
      when "Tablet" && in_digital_section
        data['infrastructure']['digital_facilities']['tablet'] = next_line.to_i if next_line =~ /^\d+$/
      when "Printer" && in_digital_section
        data['infrastructure']['digital_facilities']['printer'] = next_line.to_i if next_line =~ /^\d+$/
      when "Projector" && in_digital_section
        data['infrastructure']['digital_facilities']['projector'] = next_line.to_i if next_line =~ /^\d+$/
      when "DigiBoard" && in_digital_section
        data['infrastructure']['digital_facilities']['digiboard'] = next_line.to_i if next_line =~ /^\d+$/
      
      # Academic
      when "Medium of Instruction"
        in_digital_section = false
        in_medium_section = true
      when /^Medium (\d)$/ && in_medium_section
        if next_line && !next_line.match?(/^Medium/) && !next_line.match?(/^Visit/)
          data['academic']['medium_of_instruction']["medium_#{$1}"] = next_line
        end
      
      # Academic Hours and Days
      when "Instructional days"
        if next_line =~ /^\d+$/
          data['academic']['hours']['instructional_days'] = next_line.to_i
        end
      when "Avg.School hrs.Std."
        if next_line =~ /^\d+\.?\d*$/
          data['academic']['hours']['avg_school_hours_std'] = next_line.to_f
        end
      when "Avg.School hrs.Tch."
        if next_line =~ /^\d+\.?\d*$/
          data['academic']['hours']['avg_school_hours_tch'] = next_line.to_f
        end
      
      # Teachers
      when "Teachers"
        in_teacher_section = true
        in_digital_section = false
        in_medium_section = false
      when "Regular" && in_teacher_section
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['regular'] = next_line.to_i
        end
      when "Part-time" && in_teacher_section
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['part_time'] = next_line.to_i
        end
      when "Contract" && in_teacher_section
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['contract'] = next_line.to_i
        end
      when "Male"
        if next_line =~ /^\d+$/
          data['teachers']['demographics']['male'] = next_line.to_i
        end
      when "Female"
        if next_line =~ /^\d+$/
          data['teachers']['demographics']['female'] = next_line.to_i
        end
      when "Transgender"
        if next_line =~ /^\d+$/
          data['teachers']['demographics']['transgender'] = next_line.to_i
        end
      
      # Teacher Qualifications
      when "Below Graduate"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['below_graduate'] = next_line.to_i
        end
      when "Post Graduate and Above"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['post_graduate_and_above'] = next_line.to_i
        end
      when "Total Teacher Trained in Computer"
        if next_line =~ /^\d+$/
          data['teachers']['training']['computer_trained'] = next_line.to_i
        end
      
      # Residential Info
      when "Residential School"
        data['facilities']['residential']['type'] = next_line if next_line
      when "Residential Type"
        data['facilities']['residential']['category'] = next_line if next_line
      when "Minority School"
        data['facilities']['residential']['minority_school'] = next_line if next_line
      
      # Student Facilities
      when "Free text books"
        if next_line =~ /^\d+$/
          data['students']['facilities']['free_textbooks'] = next_line.to_i
        end
      when "Transport"
        if next_line =~ /^\d+$/
          data['students']['facilities']['transport'] = next_line.to_i
        end
      when "Free uniform"
        if next_line =~ /^\d+$/
          data['students']['facilities']['free_uniform'] = next_line.to_i
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