class PDFBlockExtractor
  def self.extract_blocks(reader)
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
          # Collect all text blocks, remove escape characters
          text = line.match(/\((.*?)\)\s*Tj/)[1]
          text = text.gsub(/\\/, '') # Remove escape characters
          current_block[:text] << text
        elsif line.include?('ET')
          current_block[:end_line] = line.strip
          # Join all text blocks with space
          current_block[:text] = current_block[:text].join(' ')
          # Only add non-empty blocks with coordinates
          if !current_block[:text].empty? && current_block[:x] && current_block[:y]
            blocks << current_block.dup
          end
        end
      end
    end

    blocks
  end
end 