require 'minitest/autorun'
require 'fileutils'
require_relative '../school_report_parser'

class SchoolReportParserTest < Minitest::Test
  def setup
    @schools = ['carmel-2223', 'jhita-2223', 'kachora-2223', 'sarvo-2223']
  end

  def test_yaml_generation
    @schools.each do |school|
      pdf_path = File.join(File.dirname(__dir__), "samples/#{school}/#{school}.pdf")
      yaml_path = File.join(File.dirname(__dir__), "samples/#{school}/#{school}.yml")
      
      # Skip if PDF doesn't exist
      next unless File.exist?(pdf_path)
      next unless File.exist?(yaml_path)  # Skip if no benchmark YAML exists
      
      # Generate new YAML data without writing files
      actual_data = SchoolReportParser.extract_to_text(pdf_path)
      
      # Compare with benchmark
      expected = YAML.load_file(yaml_path)
      assert_equal expected, actual_data, "Generated YAML for #{school} does not match the benchmark"
    end
  end
end 