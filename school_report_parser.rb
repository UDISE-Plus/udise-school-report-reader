class SchoolReportParser
  require 'pdf-reader'

  def self.extract_to_text(pdf_path)
    raise ArgumentError, "PDF file not found" unless File.exist?(pdf_path)
    
    reader = PDF::Reader.new(pdf_path)
    content = reader.pages.map(&:raw_content).join("\n")
    
    # Create text file with same name as PDF
    txt_path = pdf_path.sub(/\.pdf$/i, '.txt')
    File.write(txt_path, content)
    
    txt_path
  end
end