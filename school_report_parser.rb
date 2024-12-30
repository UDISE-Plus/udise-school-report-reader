class SchoolReportParser
  require 'pdf-reader'
  require 'yaml'
  require 'csv'
  require_relative 'enrollment_table_extractor'

  def self.extract_to_text(pdf_path)
    raise ArgumentError, "PDF file not found" unless File.exist?(pdf_path)

    reader = PDF::Reader.new(pdf_path)

    # Create text file with same name as PDF
    txt_path = pdf_path.sub(/\.pdf$/i, '.txt')
    content = reader.pages.map(&:raw_content).join("\n")
    File.write(txt_path, content)

    # Create compressed version
    compressed_content = compress_content(content)
    compressed_path = pdf_path.sub(/\.pdf$/i, '_compressed.txt')
    File.write(compressed_path, compressed_content)

    # Extract BT-ET blocks to CSV
    csv_path = pdf_path.sub(/\.pdf$/i, '_blocks.csv')
    extract_bt_et_blocks(reader, csv_path)

    # Extract rectangles to CSV
    rects_path = pdf_path.sub(/\.pdf$/i, '_rects.csv')
    extract_rectangles(reader, rects_path)

    # Combine blocks and rectangles
    combined_path = pdf_path.sub(/\.pdf$/i, '_combined.csv')
    combine_blocks_and_rects(csv_path, rects_path, combined_path)

    # Extract data points to YAML
    data_points = extract_data_points(compressed_content)
    yaml_path = pdf_path.sub(/\.pdf$/i, '.yml')
    File.write(yaml_path, data_points.to_yaml)

    # Extract enrollment table to HTML
    html_path = pdf_path.sub(/\.pdf$/i, '_enrollment.html')
    EnrollmentTableExtractor.extract_table(combined_path, html_path)
    
    [txt_path, compressed_path, yaml_path, csv_path, rects_path, combined_path, html_path]
  end

  def self.extract_bt_et_blocks(reader, csv_path)
    blocks = []

    reader.pages.each_with_index do |page, index|
      page_number = index + 1
      current_block = {}

      page.raw_content.each_line do |line|
        if line.include?('BT')
          current_block = {
            page: page_number,
            start_line: line.strip,
            text: []  # Initialize as array to collect multiple text blocks
          }
        elsif line.match?(/1\s+0\s+0\s+1\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+Tm/)
          # Only set coordinates if not already set
          unless current_block[:x] && current_block[:y]
            matches = line.match(/1\s+0\s+0\s+1\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+Tm/)
            current_block[:x] = matches[1].to_f
            current_block[:y] = matches[2].to_f
          end
        elsif line.match?(/\/F(\d+)\s+(\d+(\.\d+)?)\s+Tf/)
          # Only set font if not already set
          unless current_block[:font] && current_block[:font_size]
            matches = line.match(/\/F(\d+)\s+(\d+(\.\d+)?)\s+Tf/)
            current_block[:font] = "F#{matches[1]}"
            current_block[:font_size] = matches[2].to_f
          end
        elsif line.match?(/\((.*?)\)\s*Tj/)
          # Collect all text blocks
          current_block[:text] << line.match(/\((.*?)\)\s*Tj/)[1]
        elsif line.include?('ET')
          current_block[:end_line] = line.strip
          # Join all text blocks with space
          current_block[:text] = current_block[:text].join(' ')
          blocks << current_block.dup
        end
      end
    end

    # Write to CSV
    CSV.open(csv_path, 'wb') do |csv|
      csv << ['page', 'x', 'y', 'text', 'font', 'font_size']
      blocks.each do |block|
        csv << [
          block[:page],
          block[:x],
          block[:y],
          block[:text],
          block[:font],
          block[:font_size]
        ]
      end
    end
  end

  def self.compress_content(content)
    compressed = []
    current_block = []
    in_bt_block = false
    current_text = ""

    content.each_line do |line|
      if line.include?('BT')
        in_bt_block = true
        current_block = []
        current_text = ""
      elsif line.include?('ET')
        in_bt_block = false
        current_text = current_block.join("")
        compressed << current_text unless current_text.empty?
      elsif in_bt_block && line =~ /\((.*?)\)\s*Tj/
        # Extract text between (...) followed by Tj
        text = $1.strip
        if text =~ /^(?:Non|Residenti|al|Digit|al Facil|ities)$/
          # Special handling for split text
          current_text += text
          current_block << text
        else
          if !current_text.empty?
            compressed << current_text
          end
          current_text = text
          current_block = [text]
        end
      end
    end

    compressed.reject(&:empty?).join("\n")
  end

  def self.extract_data_points(compressed_content)
    lines = compressed_content.split("\n").map(&:strip)
    current_section = nil
    in_performance_section = false
    current_class = nil

    data = {
      'basic_info' => {},
      'location' => {},
      'school_details' => {
        'recognition' => {},
        'affiliation' => {},
        'shifts' => {},
        'special_focus' => {}
      },
      'infrastructure' => {
        'sanitation' => {
          'toilets' => {
            'boys' => {
              'total' => 0,
              'functional' => 0,
              'cwsn' => 0,
              'urinals' => 0
            },
            'girls' => {
              'total' => 0,
              'functional' => 0,
              'cwsn' => 0,
              'urinals' => 0
            }
          },
          'handwash' => {
            'near_toilet' => nil,
            'for_meal' => nil
          }
        },
        'classrooms' => {
          'total' => 0,
          'good_condition' => 0,
          'needs_minor_repair' => 0,
          'needs_major_repair' => 0,
          'other_rooms' => 0
        },
        'digital_facilities' => {
          'ict_lab' => nil,
          'internet' => nil,
          'computers' => {
            'desktop' => 0,
            'laptop' => 0,
            'tablet' => 0
          },
          'peripherals' => {
            'printer' => 0,
            'projector' => 0
          },
          'smart_classroom' => {
            'digiboard' => 0,
            'dth' => nil
          }
        },
        'other_facilities' => {},
        'building' => {
          'details' => {
            'status' => nil,
            'boundary_wall' => nil,
            'blocks' => nil,
            'pucca_blocks' => nil
          },
          'accessibility' => {
            'ramps' => nil,
            'handrails' => nil
          }
        },
        'furniture' => {
          'count' => nil
        },
        'library' => {
          'available' => nil
        }
      },
      'teachers' => {
        'count_by_level' => {},
        'qualifications' => {
          'academic' => {},
          'professional' => {
            'basic_training' => 0,
            'beled' => 0,
            'bed' => 0,
            'med' => 0,
            'other' => 0,
            'none' => 0,
            'special_education' => 0,
            'pursuing_course' => 0
          }
        },
        'demographics' => {},
        'training' => {
          'service' => {
            'total' => nil
          },
          'computer_trained' => nil
        },
        'age_distribution' => {},
        'assignments' => {
          'teaching' => {},
          'non_teaching' => {}
        },
        'classes_taught' => {},
        'attendance' => {}
      },
      'students' => {
        'facilities' => {
          'general' => {
            'transport' => {
              'primary' => 0,
              'upper_primary' => 0
            }
          },
          'incentives' => {
            'free_textbooks' => {
              'primary' => 0,
              'upper_primary' => 0
            },
            'free_uniform' => {
              'primary' => 0,
              'upper_primary' => 0
            }
          }
        }
      },
      'academic' => {
        'medium_of_instruction' => {},
        'inspections' => {
          'visits' => {
            'academic' => nil,
            'crc_coordinator' => nil,
            'block_level' => nil,
            'state_district' => nil
          }
        },
        'hours' => {
          'instructional' => {
            'days' => {
              'primary' => nil,
              'upper_primary' => nil,
              'secondary' => nil,
              'higher_secondary' => nil
            },
            'student_hours' => {
              'primary' => nil,
              'upper_primary' => nil,
              'secondary' => nil,
              'higher_secondary' => nil
            },
            'teacher_hours' => {
              'primary' => nil,
              'upper_primary' => nil,
              'secondary' => nil,
              'higher_secondary' => nil
            }
          }
        },
        'assessments' => {
          'cce' => {
            'implemented' => {
              'primary' => nil,
              'upper_primary' => nil,
              'secondary' => nil,
              'higher_secondary' => nil
            }
          }
        }
      },
      'facilities' => {
        'residential' => {
          'details' => {
            'type' => nil,
            'minority_school' => nil
          }
        },
        'basic' => {
          'water' => {},
          'electricity' => {
            'available' => nil,
            'solar_panel' => nil
          },
          'safety' => {
            'playground' => nil,
            'all_weather_road' => nil
          }
        },
        'medical' => {
          'checkups' => {
            'available' => nil
          }
        },
        'anganwadi' => {
          'at_premises' => nil,
          'boys' => nil,
          'girls' => nil,
          'worker' => nil
        }
      },
      'committees' => {
        'smc' => {
          'details' => {
            'same_as_smdc' => nil
          }
        },
        'smdc' => {
          'details' => {
            'constituted' => nil
          }
        }
      },
      'grants' => {
        'received' => {
          'amount' => nil
        },
        'expenditure' => {
          'amount' => nil
        }
      }
    }

    # Process each line
    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

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
        data['infrastructure']['building']['details']['status'] = next_line if next_line && !next_line.match?(/Boundary/)
      when "Is this a Shift School?"
        data['school_details']['shifts']['has_shifts'] = next_line if next_line && !next_line.match?(/Building/)
      when "Is Special School for CWSN?"
        data['school_details']['is_special_school'] = next_line if next_line && !next_line.match?(/Availability/)

      # Infrastructure - Building
      when "Boundary wall"
        data['infrastructure']['building']['details']['boundary_wall'] = next_line if next_line && !next_line.match?(/No\.of/)
      when "No.of Building Blocks"
        data['infrastructure']['building']['details']['blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Pucca Building Blocks"
        data['infrastructure']['building']['details']['pucca_blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Availability of Ramps"
        data['infrastructure']['building']['accessibility']['ramps'] = next_line if next_line && !next_line.match?(/Availability of Hand/)
      when "Availability of Handrails"
        data['infrastructure']['building']['accessibility']['handrails'] = next_line if next_line && !next_line.match?(/Anganwadi/)

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
        current_section = 'toilets'

        # Look ahead for toilet data
        toilet_data = []
        (i+1..i+20).each do |j|
          break if j >= lines.length
          toilet_data << lines[j]
        end

        # Try to find the values
        total_idx = toilet_data.index { |l| l =~ /Total.*CWSN/ }
        if total_idx && total_idx + 2 < toilet_data.length
          boys = toilet_data[total_idx + 1]
          girls = toilet_data[total_idx + 2]
          if boys =~ /^\d+$/ && girls =~ /^\d+$/
            data['infrastructure']['sanitation']['toilets']['boys']['total'] = boys.to_i
            data['infrastructure']['sanitation']['toilets']['girls']['total'] = girls.to_i
          end
        end

        func_idx = toilet_data.index("Functional")
        if func_idx && func_idx + 2 < toilet_data.length
          boys = toilet_data[func_idx + 1]
          girls = toilet_data[func_idx + 2]
          if boys =~ /^\d+$/ && girls =~ /^\d+$/
            data['infrastructure']['sanitation']['toilets']['boys']['functional'] = boys.to_i
            data['infrastructure']['sanitation']['toilets']['girls']['functional'] = girls.to_i
          end
        end

        cwsn_idx = toilet_data.index { |l| l =~ /CWSN Friendly/ }
        if cwsn_idx && cwsn_idx + 2 < toilet_data.length
          boys = toilet_data[cwsn_idx + 1]
          girls = toilet_data[cwsn_idx + 2]
          if boys =~ /^\d+$/ && girls =~ /^\d+$/
            data['infrastructure']['sanitation']['toilets']['boys']['cwsn'] = boys.to_i
            data['infrastructure']['sanitation']['toilets']['girls']['cwsn'] = girls.to_i
          end
        end

        urinal_idx = toilet_data.index("Urinal")
        if urinal_idx && urinal_idx + 2 < toilet_data.length
          boys = toilet_data[urinal_idx + 1]
          girls = toilet_data[urinal_idx + 2]
          if boys =~ /^\d+$/ && girls =~ /^\d+$/
            data['infrastructure']['sanitation']['toilets']['boys']['urinals'] = boys.to_i
            data['infrastructure']['sanitation']['toilets']['girls']['urinals'] = girls.to_i
          end
        end

      # Basic Facilities
      when "Handwash Near Toilet"
        data['infrastructure']['sanitation']['handwash']['near_toilet'] = next_line if next_line && !next_line.match?(/Handwash Facility/)
      when "Handwash Facility for Meal"
        data['infrastructure']['sanitation']['handwash']['for_meal'] = next_line if next_line && !next_line.match?(/Total Class/)
      when "Drinking Water Available"
        data['facilities']['basic']['water']['available'] = next_line if next_line && !next_line.match?(/Drinking Water Fun/)
      when "Drinking Water Functional"
        data['facilities']['basic']['water']['functional'] = next_line if next_line && !next_line.match?(/Rain/)
      when "Rain Water Harvesting"
        data['facilities']['basic']['water']['rain_water_harvesting'] = next_line if next_line && !next_line.match?(/Playground/)
      when "Playground Available"
        data['facilities']['basic']['safety']['playground'] = next_line if next_line && !next_line.match?(/Furniture/)
      when "Electricity Availability"
        data['facilities']['basic']['electricity']['available'] = next_line if next_line && !next_line.match?(/Solar/)
      when "Solar Panel"
        data['facilities']['basic']['electricity']['solar_panel'] = next_line if next_line && !next_line.match?(/Medical/)
      when "Library Availability"
        data['infrastructure']['library']['available'] = next_line if next_line && !next_line.match?(/Solar/)
      when "Separate Room for HM"
        data['infrastructure']['other_facilities']['hm_room'] = next_line if next_line && !next_line.match?(/Drinking/)
      when "Furniture Availability"
        if next_line =~ /^\d+$/
          data['infrastructure']['furniture']['count'] = next_line.to_i
        end

      # Infrastructure - Classrooms
      when "Total Class Rooms"
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
      when /Digital/
        current_section = 'digital'
        data['infrastructure']['digital_facilities']['ict_lab'] = lines[i + 2] if lines[i + 2] =~ /^[12]-/
        data['infrastructure']['digital_facilities']['internet'] = lines[i + 4] if lines[i + 4] =~ /^[12]-/
        if lines[i + 6] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['computers']['desktop'] = lines[i + 6].to_i
        end
        if lines[i + 8] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['computers']['laptop'] = lines[i + 8].to_i
        end
        if lines[i + 10] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['computers']['tablet'] = lines[i + 10].to_i
        end
        if lines[i + 12] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['peripherals']['printer'] = lines[i + 12].to_i
        end
        if lines[i + 14] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['peripherals']['projector'] = lines[i + 14].to_i
        end
        data['infrastructure']['digital_facilities']['smart_classroom']['dth'] = lines[i + 16] if lines[i + 16] =~ /^[12]-/
        if lines[i + 18] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['smart_classroom']['digiboard'] = lines[i + 18].to_i
        end
      when /Students/
        current_section = nil

      # Academic
      when "Medium of Instruction"
        current_section = nil
      when /^Medium (\d)$/
        medium_num = $1
        if next_line && next_line =~ /^(\d+)-(.+)$/
          code = $1
          name = $2.strip
          data['academic']['medium_of_instruction']["medium_#{medium_num}"] = {
            'code' => code,
            'name' => name
          }
        end

      # Academic Inspections
      when "Visit of school for / by"
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
        if lines[i + 1] =~ /^\d+$/
          data['academic']['hours']['instructional']['days']['primary'] = lines[i + 1].to_i
          data['academic']['hours']['instructional']['days']['upper_primary'] = lines[i + 2].to_i if lines[i + 2] =~ /^\d+$/
          data['academic']['hours']['instructional']['days']['secondary'] = lines[i + 3].to_i if lines[i + 3] =~ /^\d+$/
          data['academic']['hours']['instructional']['days']['higher_secondary'] = lines[i + 4].to_i if lines[i + 4] =~ /^\d+$/
        end
      when "Avg.School hrs.Std."
        if lines[i + 1] =~ /^\d+\.?\d*$/
          data['academic']['hours']['instructional']['student_hours']['primary'] = lines[i + 1].to_f
          data['academic']['hours']['instructional']['student_hours']['upper_primary'] = lines[i + 2].to_f if lines[i + 2] =~ /^\d+\.?\d*$/
          data['academic']['hours']['instructional']['student_hours']['secondary'] = lines[i + 3].to_f if lines[i + 3] =~ /^\d+\.?\d*$/
          data['academic']['hours']['instructional']['student_hours']['higher_secondary'] = lines[i + 4].to_f if lines[i + 4] =~ /^\d+\.?\d*$/
        end
      when "Avg.School hrs.Tch."
        if lines[i + 1] =~ /^\d+\.?\d*$/
          data['academic']['hours']['instructional']['teacher_hours']['primary'] = lines[i + 1].to_f
          data['academic']['hours']['instructional']['teacher_hours']['upper_primary'] = lines[i + 2].to_f if lines[i + 2] =~ /^\d+\.?\d*$/
          data['academic']['hours']['instructional']['teacher_hours']['secondary'] = lines[i + 3].to_f if lines[i + 3] =~ /^\d+\.?\d*$/
          data['academic']['hours']['instructional']['teacher_hours']['higher_secondary'] = lines[i + 4].to_f if lines[i + 4] =~ /^\d+\.?\d*$/
        end
      when "CCE"
        if next_line
          data['academic']['assessments']['cce']['implemented']['primary'] = next_line
          data['academic']['assessments']['cce']['implemented']['upper_primary'] = lines[i + 2] if lines[i + 2]
          data['academic']['assessments']['cce']['implemented']['secondary'] = lines[i + 3] if lines[i + 3]
          data['academic']['assessments']['cce']['implemented']['higher_secondary'] = lines[i + 4] if lines[i + 4]
        end

      # Teachers
      when "Teachers"
        current_section = nil
      when "Regular"
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['regular'] = next_line.to_i
        end
      when "Part-time"
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['part_time'] = next_line.to_i
        end
      when "Contract"
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
      
      # Teacher Assignments and Classes
      when "Total Teacher Involve in Non Teaching Assignment"
        if next_line =~ /^\d+$/
          data['teachers']['assignments']['non_teaching'] = next_line.to_i
        end
      when /^(\d+)-(.+)$/
        category = $2.strip
        if next_line =~ /^\d+$/
          key = case category
          when 'Primary'
            'primary'
          when 'Up.Pr.'
            'upper_primary'
          when 'Pr. & Up.Pr.'
            'primary_and_upper_primary'
          when 'Sec. only'
            'secondary_only'
          when 'H Sec only.'
            'higher_secondary_only'
          when 'Up pri and Sec.'
            'upper_primary_and_secondary'
          when 'Sec and H Sec'
            'secondary_and_higher_secondary'
          when 'Pre-Primary Only.'
            'pre_primary_only'
          when 'Pre- Pri & Pri'
            'pre_primary_and_primary'
          else
            category.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
          end

          data['teachers']['classes_taught'][key] = next_line.to_i
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
      # Residential Info
      when "Residential School"
        if next_line && next_line =~ /^(\d+)\s*-\s*(.+)$/
          code = $1
          type = $2.strip
          data['facilities']['residential']['details']['type'] = "#{code} - #{type}"
        end
      when "Residential Type"
        data['facilities']['residential']['details']['category'] = next_line if next_line && !next_line.match?(/Minority/)
      when "Minority School"
        data['facilities']['residential']['details']['minority_school'] = next_line if next_line && !next_line.match?(/Approachable/)
      when "Approachable By All Weather Road"
        data['facilities']['basic']['safety']['all_weather_road'] = next_line if next_line && !next_line.match?(/Toilets/)

      # Student Facilities
      when /No\.of Students Received/
        current_section = 'facilities'
        # Skip the header lines
        i += 2 # Skip "Primary" and "Up.Primary" lines
      when /Free text books/ && current_section == 'facilities'
        if lines[i + 1] =~ /^\d+$/ && lines[i + 2] =~ /^\d+$/
          data['students']['facilities']['incentives']['free_textbooks']['primary'] = lines[i + 1].to_i
          data['students']['facilities']['incentives']['free_textbooks']['upper_primary'] = lines[i + 2].to_i
        end
      when /Transport/ && current_section == 'facilities'
        if lines[i + 1] =~ /^\d+$/ && lines[i + 2] =~ /^\d+$/
          data['students']['facilities']['general']['transport']['primary'] = lines[i + 1].to_i
          data['students']['facilities']['general']['transport']['upper_primary'] = lines[i + 2].to_i
        end
      when /Free uniform/ && current_section == 'facilities'
        if lines[i + 1] =~ /^\d+$/ && lines[i + 2] =~ /^\d+$/
          data['students']['facilities']['incentives']['free_uniform']['primary'] = lines[i + 1].to_i
          data['students']['facilities']['incentives']['free_uniform']['upper_primary'] = lines[i + 2].to_i
        end

      # Committees
      when "SMC Exists"
        data['committees']['smc']['details']['exists'] = next_line if next_line && !next_line.match?(/SMC & SMDC/)
      when "SMC & SMDC Same"
        data['committees']['smc']['details']['same_as_smdc'] = next_line if next_line && !next_line.match?(/SMDC Con/)
      when "SMDC Constituted"
        data['committees']['smdc']['details']['constituted'] = next_line if next_line && !next_line.match?(/Text Books/)

      # Grants
      when "Grants Receipt"
        if next_line =~ /^\d+\.?\d*$/
          data['grants']['received']['amount'] = next_line.to_f
        end
      when "Grants Expenditure"
        if next_line =~ /^\d+\.?\d*$/
          data['grants']['expenditure']['amount'] = next_line.to_f
        end

      # Add new pattern matches
      when "Medical checkups"
        data['facilities']['medical']['checkups']['available'] = next_line if next_line

      # Library details
      when "Library Books"
        data['infrastructure']['library']['books']['total'] = next_line.to_i if next_line =~ /^\d+$/
      when "Library Type"
        data['infrastructure']['library']['details']['type'] = next_line if next_line
      when "Librarian"
        data['infrastructure']['library']['staff']['librarian'] = next_line if next_line

      # Teacher training
      when "No. of Total Teacher Received Service Training"
        data['teachers']['training']['service']['total'] = next_line.to_i if next_line =~ /^\d+$/
      when "Special Training Received"
        data['teachers']['training']['special']['received'] = next_line if next_line

      # Student performance
      when /Pass % Class (\d+)/
        class_num = $1
        if next_line =~ /^\d+\.?\d*$/
          data['academic']['assessments']['board_results']["class_#{class_num}"]['pass_percentage'] = next_line.to_f
        end

      # Sports facilities
      when "Sports Equipment"
        data['academic']['sports']['equipment']['available'] = next_line if next_line
      when "Physical Education Teacher"
        data['academic']['sports']['instructors']['available'] = next_line if next_line

      # Safety measures
      when "Fire Extinguisher"
        data['facilities']['safety']['fire']['equipment']['extinguisher'] = next_line if next_line
      when "Emergency Exit"
        data['facilities']['safety']['emergency']['exits']['available'] = next_line if next_line
      when "Security Guard"
        data['facilities']['safety']['security']['personnel']['guard'] = next_line if next_line

      # Committee meetings
      when "SMC Meetings Conducted"
        data['committees']['smc']['details']['meetings']['count'] = next_line.to_i if next_line =~ /^\d+$/
      when "SMDC Meetings Conducted"
        data['committees']['smdc']['details']['meetings']['count'] = next_line.to_i if next_line =~ /^\d+$/

      # Vocational courses
      when "Vocational Courses"
        data['academic']['vocational']['courses']['available'] = next_line if next_line
      when "Vocational Trainer"
        data['academic']['vocational']['trainers']['available'] = next_line if next_line
      # Teacher workload
      when /Teaching Hours per Week/
        if next_line =~ /(\d+)/
          data['teachers']['workload']['teaching_hours']['per_week'] = $1.to_i
        end
      when /Non-Teaching Hours/
        if next_line =~ /(\d+)/
          data['teachers']['workload']['non_teaching_hours']['per_week'] = $1.to_i
        end

      # Teacher subject-wise allocation
      when /^Subject:\s*(.+?)(?:\s*,\s*Teachers:\s*(\d+))?$/
        subject = $1.strip
        count = $2&.to_i || 0
        data['teachers']['workload']['by_subject'][subject.downcase] = count

      # Student attendance
      when /Monthly Attendance/
        current_section = 'attendance'
      when /^(\w+)\s+(\d+\.?\d*)%$/ && current_section == 'attendance'
        month = $1.downcase
        percentage = $2.to_f
        data['students']['attendance']['monthly'][month] = percentage

      # Language subjects
      when /^Language (\d+):\s*(.+)$/
        num = $1
        lang = $2.strip
        data['academic']['subjects']['languages']['details']["language_#{num}"] = lang

      # Core subjects
      when /^Core Subject (\d+):\s*(.+)$/
        num = $1
        subject = $2.strip
        data['academic']['subjects']['core']['details']["subject_#{num}"] = subject

      # Elective subjects
      when /^Elective (\d+):\s*(.+)$/
        num = $1
        subject = $2.strip
        data['academic']['subjects']['electives']['details']["elective_#{num}"] = subject

      # Classroom usage
      when /^Room (\d+) Usage:\s*(.+)$/
        room = $1
        usage = $2.strip
        data['infrastructure']['classrooms']['usage'] ||= {}
        data['infrastructure']['classrooms']['usage'][room] = usage if usage

      # Lab details
      when /^Lab Type:\s*(.+?)(?:\s*,\s*Capacity:\s*(\d+))?$/
        type = $1.strip
        capacity = $2&.to_i
        if type && capacity
          data['infrastructure']['classrooms']['labs'] ||= {}
          data['infrastructure']['classrooms']['labs'][type.downcase] = {
            'capacity' => capacity
          }
        end

      # Special room details
      when /^Special Room:\s*(.+?)(?:\s*,\s*Purpose:\s*(.+))?$/
        room = $1.strip
        purpose = $2&.strip
        if room && purpose
          data['infrastructure']['classrooms']['special_rooms'] ||= {}
          data['infrastructure']['classrooms']['special_rooms'][room.downcase] = {
            'purpose' => purpose
          }
        end

      # Student performance details
      when /^Class (\d+) Performance$/
        current_class = $1
        in_performance_section = true
      when /^(\w+)\s+(\d+\.?\d*)%$/ && in_performance_section
        subject = $1.strip.downcase
        percentage = $2.to_f
        data['students']['performance']['by_class']["class_#{current_class}"] ||= {}
        data['students']['performance']['by_class']["class_#{current_class}"][subject] = percentage

      # Committee details
      when /^Committee:\s*(.+?)(?:\s*,\s*Members:\s*(\d+))?$/
        committee = $1.strip.downcase
        members = $2&.to_i
        data['committees'][committee] ||= {}
        data['committees'][committee]['members'] = members if members

      # Safety measures
      when /^Safety Measure:\s*(.+?)(?:\s*,\s*Status:\s*(.+))?$/
        measure = $1.strip.downcase
        status = $2&.strip
        data['facilities']['safety']['measures'] ||= {}
        data['facilities']['safety']['measures'][measure] = status

      # Medical facilities
      when /^Medical Facility:\s*(.+?)(?:\s*,\s*Availability:\s*(.+))?$/
        facility = $1.strip.downcase
        availability = $2&.strip
        data['facilities']['medical']['facilities'] ||= {}
        data['facilities']['medical']['facilities'][facility] = availability

      # Sports facilities
      when /^Sport:\s*(.+?)(?:\s*,\s*Equipment:\s*(\d+))?$/
        sport = $1.strip.downcase
        equipment = $2&.to_i
        data['academic']['sports']['facilities'][sport] = {
          'equipment_count' => equipment
        }

      # Library resources
      when /^Book Category:\s*(.+?)(?:\s*,\s*Count:\s*(\d+))?$/
        category = $1.strip.downcase
        count = $2&.to_i
        data['infrastructure']['library']['books']['by_category'] ||= {}
        data['infrastructure']['library']['books']['by_category'][category] = count

      # Grant utilization
      when /^Grant Type:\s*(.+?)(?:\s*,\s*Utilization:\s*(\d+\.?\d*)%)?$/
        type = $1.strip.downcase
        utilization = $2&.to_f
        data['grants']['utilization']['by_type'] ||= {}
        data['grants']['utilization']['by_type'][type] = utilization
      when "Bachelor of Elementary Education (B.El.Ed.)"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['beled'] = next_line.to_i
        else
          data['teachers']['qualifications']['professional']['beled'] = 0
        end
      when "Other"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['other'] = next_line.to_i
        end
      when "None"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['none'] = next_line.to_i
        end
      when "Diploma/degree in special Education"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['special_education'] = next_line.to_i
        end
      when "Pursuing any Relevant Professional Course"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['pursuing_course'] = next_line.to_i
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

  def self.extract_rectangles(reader, rects_path)
    rectangles = []
    current_color = '0 G'  # Default stroke color (black)
    current_fill_color = '1 1 1 rg'  # Default fill color (white)
    current_line_width = 1.0  # Default line width

    reader.pages.each_with_index do |page, index|
      page_number = index + 1

      page.raw_content.each_line do |line|
        # Track stroke color changes
        if line.match?(/[\d.]+ [\d.]+ [\d.]+ RG/) || line.match?(/[\d.]+ G/)
          current_color = line.strip
        end

        # Track fill color changes
        if line.match?(/[\d.]+ [\d.]+ [\d.]+ rg/) || line.match?(/[\d.]+ g/)
          current_fill_color = line.strip
        end

        # Track line width changes
        if line.match?(/[\d.]+\s+w/)
          if match = line.match(/(\d+\.?\d*)\s+w/)
            current_line_width = match[1].to_f
          end
        end

        # Look for rectangles (table cells)
        if line.match?(/(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+re/)
          matches = line.match(/(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+re/)
          x, y, width, height = matches[1..4].map(&:to_f)

          # Store the rectangle with its properties
          rectangles << {
            page: page_number,
            x: x,
            y: y,
            width: width,
            height: height,
            stroke_color: current_color,
            fill_color: current_fill_color,
            line_width: current_line_width
          }
        end
      end
    end

    # Write to CSV
    CSV.open(rects_path, 'wb') do |csv|
      csv << ['page', 'x', 'y', 'width', 'height', 'stroke_color', 'fill_color', 'line_width']
      rectangles.each do |rect|
        csv << [
          rect[:page],
          rect[:x],
          rect[:y],
          rect[:width],
          rect[:height],
          rect[:stroke_color],
          rect[:fill_color],
          rect[:line_width]
        ]
      end
    end
  end

  def self.combine_blocks_and_rects(blocks_path, rects_path, output_path)
    # Read blocks
    blocks = []
    CSV.foreach(blocks_path, headers: true) do |row|
      blocks << {
        page: row['page'].to_i,
        x: row['x'].to_f,
        y: row['y'].to_f,
        text: row['text'],
        font: row['font'],
        font_size: row['font_size'].to_f
      }
    end

    # Read rectangles
    rects = []
    CSV.foreach(rects_path, headers: true) do |row|
      rects << {
        page: row['page'].to_i,
        x: row['x'].to_f,
        y: row['y'].to_f,
        width: row['width'].to_f,
        height: row['height'].to_f,
        stroke_color: row['stroke_color'],
        fill_color: row['fill_color'],
        line_width: row['line_width'].to_f
      }
    end

    # For each text block, find its smallest containing rectangle
    combined_data = blocks.map do |block|
      # Find rectangles on the same page that contain this text block
      containing_rects = rects.select do |rect|
        rect[:page] == block[:page] &&
        block[:x] >= rect[:x] &&
        block[:x] <= (rect[:x] + rect[:width]) &&
        block[:y] >= rect[:y] &&
        block[:y] <= (rect[:y] + rect[:height])
      end

      # Find the smallest containing rectangle by area
      smallest_rect = containing_rects.min_by { |r| r[:width] * r[:height] }

      # Create entry with block data and rectangle data (if found)
      if smallest_rect
        {
          page: block[:page],
          text: block[:text],
          text_x: block[:x],
          text_y: block[:y],
          font: block[:font],
          font_size: block[:font_size],
          rect_x: smallest_rect[:x],
          rect_y: smallest_rect[:y],
          rect_width: smallest_rect[:width],
          rect_height: smallest_rect[:height],
          stroke_color: smallest_rect[:stroke_color],
          fill_color: smallest_rect[:fill_color],
          line_width: smallest_rect[:line_width]
        }
      else
        {
          page: block[:page],
          text: block[:text],
          text_x: block[:x],
          text_y: block[:y],
          font: block[:font],
          font_size: block[:font_size],
          rect_x: nil,
          rect_y: nil,
          rect_width: nil,
          rect_height: nil,
          stroke_color: nil,
          fill_color: nil,
          line_width: nil
        }
      end
    end

    # Add empty rectangles that don't contain any text
    rects.each do |rect|
      # Check if this rectangle contains any text blocks
      has_text = blocks.any? do |block|
        block[:page] == rect[:page] &&
        block[:x] >= rect[:x] &&
        block[:x] <= (rect[:x] + rect[:width]) &&
        block[:y] >= rect[:y] &&
        block[:y] <= (rect[:y] + rect[:height])
      end

      # If it doesn't contain text, add it as an empty entry
      unless has_text
        combined_data << {
          page: rect[:page],
          text: "",
          text_x: nil,
          text_y: nil,
          font: nil,
          font_size: nil,
          rect_x: rect[:x],
          rect_y: rect[:y],
          rect_width: rect[:width],
          rect_height: rect[:height],
          stroke_color: rect[:stroke_color],
          fill_color: rect[:fill_color],
          line_width: rect[:line_width]
        }
      end
    end

    # Sort by page, then y (top to bottom), then x (left to right)
    combined_data.sort_by! do |data|
      [
        data[:page],
        -(data[:rect_y] || data[:text_y] || 0),  # Negative for top-to-bottom
        data[:rect_x] || data[:text_x] || 0
      ]
    end

    # Write combined data to CSV
    CSV.open(output_path, 'wb') do |csv|
      csv << [
        'page',
        'text',
        'text_x',
        'text_y',
        'font',
        'font_size',
        'rect_x',
        'rect_y',
        'rect_width',
        'rect_height',
        'stroke_color',
        'fill_color',
        'line_width'
      ]

      combined_data.each do |data|
        csv << [
          data[:page],
          data[:text],
          data[:text_x],
          data[:text_y],
          data[:font],
          data[:font_size],
          data[:rect_x],
          data[:rect_y],
          data[:rect_width],
          data[:rect_height],
          data[:stroke_color],
          data[:fill_color],
          data[:line_width]
        ]
      end
    end
  end
end
