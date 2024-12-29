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
      'school_details' => {
        'recognition' => {},
        'affiliation' => {}
      },
      'infrastructure' => {
        'toilets' => {},
        'classrooms' => {},
        'digital_facilities' => {},
        'other_facilities' => {},
        'building' => {},
        'furniture' => {}
      },
      'teachers' => {
        'count_by_level' => {},
        'qualifications' => {
          'academic' => {},
          'professional' => {}
        },
        'demographics' => {},
        'training' => {},
        'age_distribution' => {},
        'assignments' => {}
      },
      'students' => {
        'enrollment' => {
          'general' => {},
          'by_class' => {
            'pre_primary' => { 'boys' => 0, 'girls' => 0 },
            'class_1' => { 'boys' => 0, 'girls' => 0 },
            'class_2' => { 'boys' => 0, 'girls' => 0 },
            'class_3' => { 'boys' => 0, 'girls' => 0 },
            'class_4' => { 'boys' => 0, 'girls' => 0 },
            'class_5' => { 'boys' => 0, 'girls' => 0 },
            'class_6' => { 'boys' => 0, 'girls' => 0 },
            'class_7' => { 'boys' => 0, 'girls' => 0 },
            'class_8' => { 'boys' => 0, 'girls' => 0 },
            'class_9' => { 'boys' => 0, 'girls' => 0 },
            'class_10' => { 'boys' => 0, 'girls' => 0 },
            'class_11' => { 'boys' => 0, 'girls' => 0 },
            'class_12' => { 'boys' => 0, 'girls' => 0 }
          },
          'by_social_category' => {},
          'cwsn' => {}
        },
        'facilities' => {},
        'scholarships' => {}
      },
      'academic' => {
        'medium_of_instruction' => {},
        'inspections' => {
          'visits' => {},
          'officers' => {}
        },
        'hours' => {},
        'subjects' => {},
        'assessments' => {}
      },
      'facilities' => {
        'residential' => {},
        'basic' => {},
        'safety' => {},
        'medical' => {},
        'anganwadi' => {}
      },
      'committees' => {
        'smc' => {},
        'smdc' => {}
      },
      'grants' => {
        'received' => {},
        'expenditure' => {}
      }
    }

    lines = compressed_content.split("\n").map(&:strip)
    current_section = nil
    current_subsection = nil
    in_toilet_section = false
    in_digital_section = false
    in_teacher_section = false
    in_medium_section = false
    in_student_section = false
    in_grant_section = false
    in_enrollment_section = false

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
      when /Academic Year.*:\s*(\d{4}-\d{2})/
        data['basic_info']['academic_year'] = $1
      
      # Location
      when "State"
        data['location']['state'] = next_line if next_line && !next_line.match?(/District/)
      when "District"
        data['location']['district'] = next_line if next_line && !next_line.match?(/Block/)
      when "Block"
        data['location']['block'] = next_line if next_line && !next_line.match?(/Rural/)
      when "Rural / Urban"
        data['location']['area_type'] = next_line if next_line && !next_line.match?(/Cluster/)
      when "Pincode"
        data['location']['pincode'] = next_line if next_line && next_line.match?(/^\d+$/)
      when "Ward"
        data['location']['ward'] = next_line if next_line && !next_line.match?(/Mohalla/)
      when "Cluster"
        data['location']['cluster'] = next_line if next_line && !next_line.match?(/Ward/)
      when "Municipality"
        data['location']['municipality'] = next_line if next_line && !next_line.match?(/Assembly/)
      when "Assembly Const."
        data['location']['assembly_constituency'] = next_line if next_line && !next_line.match?(/Parl/)
      when "Parl. Constituency"
        data['location']['parliamentary_constituency'] = next_line if next_line && !next_line.match?(/School/)
      
      # School Details
      when "School Category"
        data['school_details']['category'] = next_line if next_line && !next_line.match?(/School Management/)
      when "School Management"
        data['school_details']['management'] = next_line if next_line && !next_line.match?(/School Type/)
      when "School Type"
        data['school_details']['type'] = next_line if next_line && !next_line.match?(/Lowest/)
      when "Lowest & Highest Class"
        data['school_details']['class_range'] = next_line if next_line && !next_line.match?(/Pre Primary/)
      when "Pre Primary"
        data['school_details']['pre_primary'] = next_line if next_line && !next_line.match?(/Medium/)
      when "Year of Establishment"
        data['school_details']['established'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Pri."
        data['school_details']['recognition']['primary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Upr.Pri."
        data['school_details']['recognition']['upper_primary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Sec."
        data['school_details']['recognition']['secondary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Higher Sec."
        data['school_details']['recognition']['higher_secondary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Affiliation Board-Sec"
        data['school_details']['affiliation']['secondary'] = next_line if next_line && !next_line.match?(/Affiliation Board-HSec/)
      when "Affiliation Board-HSec"
        data['school_details']['affiliation']['higher_secondary'] = next_line if next_line && !next_line.match?(/Is this/)
      when "Building Status"
        data['school_details']['building_status'] = next_line if next_line && !next_line.match?(/Boundary/)
      when "Is this a Shift School?"
        data['school_details']['is_shift_school'] = next_line if next_line && !next_line.match?(/Building/)
      when "Is Special School for CWSN?"
        data['school_details']['is_special_school'] = next_line if next_line && !next_line.match?(/Availability/)
      
      # Infrastructure - Building
      when "Boundary wall"
        data['infrastructure']['building']['boundary_wall'] = next_line if next_line && !next_line.match?(/No\.of/)
      when "No.of Building Blocks"
        data['infrastructure']['building']['blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Pucca Building Blocks"
        data['infrastructure']['building']['pucca_blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Availability of Ramps"
        data['infrastructure']['building']['ramps'] = next_line if next_line && !next_line.match?(/Availability of Hand/)
      when "Availability of Handrails"
        data['infrastructure']['building']['handrails'] = next_line if next_line && !next_line.match?(/Anganwadi/)
      
      # Anganwadi
      when "Anganwadi At Premises"
        data['facilities']['anganwadi']['at_premises'] = next_line if next_line
      when "Anganwadi Boys"
        data['facilities']['anganwadi']['boys'] = next_line.to_i if next_line =~ /^\d+$/
      when "Anganwadi Girls"
        data['facilities']['anganwadi']['girls'] = next_line.to_i if next_line =~ /^\d+$/
      when "Anganwadi Worker"
        data['facilities']['anganwadi']['worker'] = next_line if next_line
      
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
        data['facilities']['basic']['handwash_near_toilet'] = next_line if next_line && !next_line.match?(/Handwash Facility/)
      when "Handwash Facility for Meal"
        data['facilities']['basic']['handwash_for_meal'] = next_line if next_line && !next_line.match?(/Total Class/)
      when "Drinking Water Available"
        data['facilities']['basic']['drinking_water'] = next_line if next_line && !next_line.match?(/Drinking Water Fun/)
      when "Drinking Water Functional"
        data['facilities']['basic']['drinking_water_functional'] = next_line if next_line && !next_line.match?(/Rain/)
      when "Rain Water Harvesting"
        data['facilities']['basic']['rain_water_harvesting'] = next_line if next_line && !next_line.match?(/Playground/)
      when "Playground Available"
        data['facilities']['basic']['playground'] = next_line if next_line && !next_line.match?(/Furniture/)
      when "Electricity Availability"
        data['facilities']['basic']['electricity'] = next_line if next_line && !next_line.match?(/Solar/)
      when "Solar Panel"
        data['facilities']['basic']['solar_panel'] = next_line if next_line && !next_line.match?(/Medical/)
      when "Library Availability"
        data['facilities']['basic']['library'] = next_line if next_line && !next_line.match?(/Separate/)
      when "Separate Room for HM"
        data['facilities']['basic']['separate_hm_room'] = next_line if next_line && !next_line.match?(/Drinking/)
      when "Furniture Availability"
        if next_line =~ /^\d+$/
          data['infrastructure']['furniture']['count'] = next_line.to_i
        end
      
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
        data['infrastructure']['digital_facilities']['ict_lab'] = next_line if next_line && !next_line.match?(/Internet/)
      when "Internet" && in_digital_section
        data['infrastructure']['digital_facilities']['internet'] = next_line if next_line && !next_line.match?(/Desktop/)
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
      when "DTH" && in_digital_section
        data['infrastructure']['digital_facilities']['dth'] = next_line if next_line && !next_line.match?(/DigiBoard/)
      
      # Academic
      when "Medium of Instruction"
        in_digital_section = false
        in_medium_section = true
      when /^Medium (\d)$/ && in_medium_section
        if next_line && !next_line.match?(/^Medium/) && !next_line.match?(/^Visit/)
          data['academic']['medium_of_instruction']["medium_#{$1}"] = next_line
        end
      
      # Academic Inspections
      when "Visit of school for / by"
        in_medium_section = false
      when "Acad. Inspections"
        data['academic']['inspections']['visits']['academic'] = next_line.to_i if next_line =~ /^\d+$/
      when "CRC Coordinator"
        data['academic']['inspections']['visits']['crc_coordinator'] = next_line.to_i if next_line =~ /^\d+$/
      when "Block Level Officers"
        data['academic']['inspections']['visits']['block_level'] = next_line.to_i if next_line =~ /^\d+$/
      when "State/District Officers"
        data['academic']['inspections']['visits']['state_district'] = next_line.to_i if next_line =~ /^\d+$/
      
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
      when "CCE"
        data['academic']['assessments']['cce'] = next_line if next_line && !next_line.match?(/Total/)
      
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
      
      # Teacher Assignments
      when "Total Teacher Involve in Non Teaching Assignment"
        if next_line =~ /^\d+$/
          data['teachers']['assignments']['non_teaching'] = next_line.to_i
        end
      
      # Teacher Qualifications
      when "Below Graduate"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['academic']['below_graduate'] = next_line.to_i
        end
      when "Graduate"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['academic']['graduate'] = next_line.to_i
        end
      when "Post Graduate and Above"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['academic']['post_graduate_and_above'] = next_line.to_i
        end
      when "Diploma or Certificate in basic teachers training"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['basic_training'] = next_line.to_i
        end
      when "B.Ed. or Equivalent"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['bed'] = next_line.to_i
        end
      when "M.Ed. or Equivalent"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['med'] = next_line.to_i
        end
      when "Total Teacher Trained in Computer"
        if next_line =~ /^\d+$/
          data['teachers']['training']['computer_trained'] = next_line.to_i
        end
      when "Teachers Aged above 55"
        if next_line =~ /^\d+$/
          data['teachers']['age_distribution']['above_55'] = next_line.to_i
        end
      
      # Student Enrollment
      when "Total no. of Students Enrolled Under Section 12 of the RTE Act"
        in_enrollment_section = true
      when /^Class ([IVX]+)$/ && in_enrollment_section
        class_num = roman_to_arabic($1)
        if class_num && next_line =~ /^B\s+G$/
          boys = lines[i + 2]&.strip.to_i
          girls = lines[i + 3]&.strip.to_i
          data['students']['enrollment']['by_class']["class_#{class_num}"]['boys'] = boys
          data['students']['enrollment']['by_class']["class_#{class_num}"]['girls'] = girls
        end
      
      # Residential Info
      when "Residential School"
        data['facilities']['residential']['type'] = next_line if next_line && !next_line.match?(/Residential Type/)
      when "Residential Type"
        data['facilities']['residential']['category'] = next_line if next_line && !next_line.match?(/Minority/)
      when "Minority School"
        data['facilities']['residential']['minority_school'] = next_line if next_line && !next_line.match?(/Approachable/)
      when "Approachable By All Weather Road"
        data['facilities']['residential']['all_weather_road'] = next_line if next_line && !next_line.match?(/Toilets/)
      
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
      
      # Committees
      when "SMC Exists"
        data['committees']['smc']['exists'] = next_line if next_line && !next_line.match?(/SMC & SMDC/)
      when "SMC & SMDC Same"
        data['committees']['smc']['same_as_smdc'] = next_line if next_line && !next_line.match?(/SMDC Con/)
      when "SMDC Constituted"
        data['committees']['smdc']['constituted'] = next_line if next_line && !next_line.match?(/Text Books/)
      
      # Grants
      when "Grants Receipt"
        if next_line =~ /^\d+\.?\d*$/
          data['grants']['received']['amount'] = next_line.to_f
        end
      when "Grants Expenditure"
        if next_line =~ /^\d+\.?\d*$/
          data['grants']['expenditure']['amount'] = next_line.to_f
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

  private

  def self.roman_to_arabic(roman)
    roman_values = {
      'I' => 1,
      'V' => 5,
      'X' => 10,
      'L' => 50,
      'C' => 100,
      'D' => 500,
      'M' => 1000
    }
    
    result = 0
    prev_value = 0
    
    roman.reverse.each_char do |char|
      curr_value = roman_values[char]
      if curr_value >= prev_value
        result += curr_value
      else
        result -= curr_value
      end
      prev_value = curr_value
    end
    
    result
  end
end