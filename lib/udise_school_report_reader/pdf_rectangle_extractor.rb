class PDFRectangleExtractor
  def self.extract_rectangles(reader)
    raise ArgumentError, "PDF reader cannot be nil" if reader.nil?
    
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
end 