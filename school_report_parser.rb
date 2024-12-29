class SchoolReportParser
  require 'pdf-reader'

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
    
    [txt_path, compressed_path]
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
        block_text = current_block.reject(&:empty?).join(" ")
        compressed << block_text unless block_text.empty?
      elsif in_bt_block && line =~ /\((.*?)\)\s*Tj/
        # Extract text between (...) followed by Tj
        text = $1.strip
        current_block << text unless text.empty?
      end
    end

    compressed.reject(&:empty?).join("\n")
  end
end