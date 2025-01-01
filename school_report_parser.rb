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
require_relative 'sanitation_data_reader'
require_relative 'location_data_reader'
require_relative 'basic_info_data_reader'
require_relative 'official_data_reader'
require_relative 'characteristics_reader'
require_relative 'digital_facilities_data_reader'
require_relative 'anganwadi_data_reader'
require_relative 'building_data_reader'
require_relative 'rooms_data_reader'
require_relative 'pdf_block_extractor'
require_relative 'csv_writer'
require_relative 'pdf_rectangle_extractor'
require_relative 'pdf_content_compressor'
require_relative 'block_rectangle_combiner'
require_relative 'activities_data_reader'

class SchoolReportParser
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
    compressed_content = PDFContentCompressor.compress(content)
    
    # Extract blocks and rectangles
    blocks = PDFBlockExtractor.extract_blocks(reader)
    rectangles = PDFRectangleExtractor.extract_rectangles(reader)
    combined_data = BlockRectangleCombiner.combine(blocks, rectangles)
    
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

  def self.extract_data_points(compressed_content)
    lines = compressed_content.split("\n").map { |line| line.strip.gsub(/\\/, '') }  # Remove escape characters

    # Load template as base structure
    data = YAML.load_file('template.yml')

    # Extract data using readers
    basic_info_data = BasicInfoDataReader.read(lines)
    location_data = LocationDataReader.read(lines)
    official_data = OfficialDataReader.read(lines)
    characteristics_data = CharacteristicsReader.read(lines)
    digital_facilities_data = DigitalFacilitiesDataReader.read(lines)
    anganwadi_data = AnganwadiDataReader.read(lines)
    building_data = BuildingDataReader.read(lines)
    rooms_data = RoomsDataReader.read(lines)
    teacher_data = TeacherDataReader.read(lines)
    sanitation_data = SanitationDataReader.read(lines)
    activities_data = ActivitiesDataReader.read(lines)

    # Merge data from readers
    data.merge!(basic_info_data) if basic_info_data
    data.merge!(location_data) if location_data
    data.merge!(official_data) if official_data
    data.merge!(characteristics_data) if characteristics_data
    data.merge!(digital_facilities_data) if digital_facilities_data
    data.merge!(anganwadi_data) if anganwadi_data
    data.merge!(building_data) if building_data
    data.merge!(rooms_data) if rooms_data
    data.merge!(teacher_data) if teacher_data
    data.merge!(activities_data) if activities_data
    data.merge!(sanitation_data) if sanitation_data

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      # Basic Facilities
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
      when "Furniture Availability"
        if next_line =~ /^\d+$/
          data['infrastructure']['furniture']['count'] = next_line.to_i
        end

      # Academic
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
      when /Free text books/
        if lines[i + 1] =~ /^\d+$/ && lines[i + 2] =~ /^\d+$/
          data['students']['facilities']['incentives']['free_textbooks']['primary'] = lines[i + 1].to_i
          data['students']['facilities']['incentives']['free_textbooks']['upper_primary'] = lines[i + 2].to_i
        end
      when /Transport/
        if lines[i + 1] =~ /^\d+$/ && lines[i + 2] =~ /^\d+$/
          data['students']['facilities']['general']['transport']['primary'] = lines[i + 1].to_i
          data['students']['facilities']['general']['transport']['upper_primary'] = lines[i + 2].to_i
        end
      when /Free uniform/
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

      # Medical facilities
      when "Medical checkups"
        data['facilities']['medical']['checkups']['available'] = next_line if next_line

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
end
