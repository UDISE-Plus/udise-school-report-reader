require 'minitest/autorun'
require 'fileutils'
require_relative '../school_report_parser'

class SchoolReportParserTest < Minitest::Test
  def setup
    @schools = ['carmel-2223', 'jhita-2223', 'kachora-2223', 'sarvo-2223']
    
    # Backup existing YAML files
    @schools.each do |school|
      yaml_path = File.join(File.dirname(__dir__), "samples/#{school}/#{school}.yml")
      if File.exist?(yaml_path)
        FileUtils.cp(yaml_path, "#{yaml_path}.bak")
      end
    end
  end

  def teardown
    # Restore YAML files from backups
    @schools.each do |school|
      yaml_path = File.join(File.dirname(__dir__), "samples/#{school}/#{school}.yml")
      backup_path = "#{yaml_path}.bak"
      if File.exist?(backup_path)
        FileUtils.mv(backup_path, yaml_path)
      end
    end
  end

  def test_yaml_generation
    @schools.each do |school|
      pdf_path = File.join(File.dirname(__dir__), "samples/#{school}/#{school}.pdf")
      yaml_path = File.join(File.dirname(__dir__), "samples/#{school}/#{school}.yml")
      backup_path = "#{yaml_path}.bak"

      # Skip if PDF doesn't exist
      next unless File.exist?(pdf_path)
      
      # Generate new YAML
      SchoolReportParser.extract_to_text(pdf_path)
      
      # Compare with backup
      if File.exist?(backup_path)
        expected = YAML.load_file(backup_path)
        actual = YAML.load_file(yaml_path)
        assert_equal expected, actual, "Generated YAML for #{school} does not match the benchmark"
      end
    end
  end
end 