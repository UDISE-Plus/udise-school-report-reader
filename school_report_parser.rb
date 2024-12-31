class SchoolReportParser
  require 'pdf-reader'
  require 'yaml'
  require 'csv'
  require 'fileutils'
  require 'tempfile'
  require_relative 'enrollment_data_reader'
  require_relative 'enrollment_html_writer'
  require_relative 'enrollment_yaml_writer'
  require_relative 'ews_data_reader'
  require_relative 'ews_html_writer'
  require_relative 'ews_yaml_writer'
  require_relative 'rte_data_reader'
  require_relative 'rte_html_writer'
  require_relative 'rte_yaml_writer'
  require_relative 'teacher_data_reader'
  require_relative 'pdf_block_extractor'
  require_relative 'csv_writer'

  def self.extract_to_text(pdf_path, output_dir = nil, write_files = false)
    raise ArgumentError, "PDF file not found" unless File.exist?(pdf_path)

    # Extract all data first
    extracted_data = extract_data(pdf_path)
    
    # Write files if requested
    write_output_files(pdf_path, extracted_data, output_dir) if write_files
    
    # Return the YAML data
    extracted_data[:yaml_data]
  end

  private

  def self.extract_data(pdf_path)
    reader = PDF::Reader.new(pdf_path)
    
    # Extract raw content
    content = reader.pages.map(&:raw_content).join("\n")
    compressed_content = compress_content(content)
    
    # Extract blocks and rectangles
    blocks = PDFBlockExtractor.extract_blocks(reader)
    rectangles = extract_rectangles(reader)
    combined_data = combine_blocks_and_rects(blocks, rectangles)
    
    # Extract YAML data
    yaml_data = extract_data_points(compressed_content)
    
    # Create temporary file for combined data
    temp_file = Tempfile.new(['combined', '.csv'])
    begin
      CSVWriter.write_combined(combined_data, temp_file.path)
      
      # Extract table data using the temp file
      enrollment_data = EnrollmentDataReader.read(temp_file.path)
      ews_data = EwsDataReader.read(temp_file.path)
      rte_data = RteDataReader.read(temp_file.path)
      
      # Format table data for YAML
      yaml_data['enrollment_data'] = EnrollmentYamlWriter.format_yaml(enrollment_data) if enrollment_data
      yaml_data['ews_data'] = EwsYamlWriter.format_yaml(ews_data)
      yaml_data['rte_data'] = RteYamlWriter.format_yaml(rte_data)
      
      {
        content: content,
        compressed_content: compressed_content,
        blocks: blocks,
        rectangles: rectangles,
        combined_data: combined_data,
        enrollment_data: enrollment_data,
        ews_data: ews_data,
        rte_data: rte_data,
        yaml_data: yaml_data
      }
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def self.write_output_files(pdf_path, data, output_dir)
    paths = OutputPaths.new(pdf_path, output_dir)
    
    # Write text files
    File.write(paths.txt, data[:content])
    File.write(paths.compressed_txt, data[:compressed_content])
    
    # Write CSV files
    CSVWriter.write_blocks(data[:blocks], paths.blocks_csv)
    CSVWriter.write_rectangles(data[:rectangles], paths.rects_csv)
    CSVWriter.write_combined(data[:combined_data], paths.combined_csv)
    
    # Write HTML files
    RteHtmlWriter.generate_html(data[:rte_data], paths.rte_html)
    EnrollmentHtmlWriter.generate_html(data[:enrollment_data], paths.enrollment_html)
    EwsHtmlWriter.generate_html(data[:ews_data], paths.ews_html)
    
    # Write YAML file
    File.write(paths.yaml, data[:yaml_data].to_yaml)
  end

  class OutputPaths
    EXTENSIONS = {
      txt: '.txt',
      compressed_txt: '_compressed.txt',
      blocks_csv: '_blocks.csv',
      rects_csv: '_rects.csv',
      combined_csv: '_combined.csv',
      rte_html: '_rte.html',
      enrollment_html: '_enrollment.html',
      ews_html: '_ews.html',
      yaml: '.yml'
    }

    def initialize(pdf_path, output_dir)
      @pdf_path = pdf_path
      @output_dir = output_dir
      @base_name = File.basename(pdf_path, '.pdf')
    end

    EXTENSIONS.each do |name, ext|
      define_method(name) do
        if @output_dir
          File.join(@output_dir, "#{@base_name}#{ext}")
        elsif name == :yaml
          File.join(File.dirname(@pdf_path), "#{@base_name}#{ext}")
        else
          tmp_dir = File.join(File.expand_path('.'), 'tmp')
          FileUtils.mkdir_p(tmp_dir)
          File.join(tmp_dir, "#{@base_name}#{ext}")
        end
      end
    end
  end

  def self.extract_rectangles(reader)
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

    rectangles
  end

  def self.write_rectangles_to_csv(rectangles, rects_path)
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

  def self.combine_blocks_and_rects(blocks, rects)
    # Filter out blocks with missing coordinates
    invalid_blocks = blocks.reject { |block| block[:x] && block[:y] || block[:text].to_s.empty? }
    if invalid_blocks.any?
      warn "Warning: Found #{invalid_blocks.size} non-empty blocks with missing coordinates"
      invalid_blocks.each do |block|
        warn "  - Page #{block[:page]}: '#{block[:text]}'"
      end
    end
    valid_blocks = blocks.select { |block| block[:x] && block[:y] }
    
    # Filter out rectangles with missing or invalid coordinates
    invalid_rects = rects.reject { |rect| rect[:x] && rect[:y] && rect[:width] && rect[:height] && rect[:width] > 0 && rect[:height] > 0 }
    if invalid_rects.any?
      warn "Warning: Found #{invalid_rects.size} rectangles with invalid coordinates"
      invalid_rects.each do |rect|
        warn "  - Page #{rect[:page]}: x=#{rect[:x]}, y=#{rect[:y]}, w=#{rect[:width]}, h=#{rect[:height]}"
      end
    end
    valid_rects = rects.select { |rect| rect[:x] && rect[:y] && rect[:width] && rect[:height] && rect[:width] > 0 && rect[:height] > 0 }
    
    # For each text block, find its smallest containing rectangle
    combined_data = valid_blocks.map do |block|
      # Find rectangles on the same page that contain this text block
      containing_rects = valid_rects.select do |rect|
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
    valid_rects.each do |rect|
      # Check if this rectangle contains any text blocks
      has_text = valid_blocks.any? do |block|
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

    combined_data
  end

  def self.write_combined_to_csv(combined_data, output_path)
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
    lines = compressed_content.split("\n").map { |line| line.strip.gsub(/\\/, '') }  # Remove escape characters

    # Load template as base structure
    data = YAML.load_file('template.yml')

    # Extract teacher data
    teacher_data = TeacherDataReader.read(lines)
    data.merge!(teacher_data) if teacher_data

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
end
