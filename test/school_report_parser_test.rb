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
      compare_nested_hashes(expected, actual_data, [], school)
    end
  end

  private

  def compare_nested_hashes(expected, actual, path = [], school)
    return if expected == actual

    if expected.is_a?(Hash) && actual.is_a?(Hash)
      # Check for missing keys
      (expected.keys - actual.keys).each do |key|
        flunk "Missing key '#{(path + [key]).join('.')}' in #{school}"
      end

      # Check for extra keys
      (actual.keys - expected.keys).each do |key|
        flunk "Extra key '#{(path + [key]).join('.')}' in #{school}"
      end

      # Compare values for common keys
      (expected.keys & actual.keys).each do |key|
        compare_nested_hashes(expected[key], actual[key], path + [key], school)
      end
    elsif expected.is_a?(Array) && actual.is_a?(Array)
      if expected.length != actual.length
        flunk "Array length mismatch at '#{path.join('.')}' in #{school}. Expected #{expected.length}, got #{actual.length}"
      end
      expected.zip(actual).each_with_index do |(exp_item, act_item), idx|
        compare_nested_hashes(exp_item, act_item, path + [idx], school)
      end
    else
      assert_equal expected, actual, "Value mismatch at '#{path.join('.')}' in #{school}. Expected #{expected.inspect}, got #{actual.inspect}"
    end
  end
end 