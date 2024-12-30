require_relative 'enrollment_data_reader'
require_relative 'enrollment_html_writer'
require 'csv'

class EnrollmentTableExtractor
  def self.extract_table(combined_path, html_path)
    data = EnrollmentDataReader.read_data(combined_path)
    EnrollmentHtmlWriter.generate_html(data, html_path)
  end
end 