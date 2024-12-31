class BlockRectangleCombiner
  def self.combine(blocks, rects)
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
end 