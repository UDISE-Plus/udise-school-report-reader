class EwsDataReader
  def self.read(csv_path) = new(csv_path).read

  def initialize(csv_path) = @csv_path = csv_path

  def read
    # Initialize arrays for different cell types
    grade_cells = []
    bg_cells = []
    ews_cells = []

    CSV.foreach(@csv_path, headers: true) do |cell|
      if cell['page'] == '1'
        if ['Pre-Pri.', 'Class I', 'Class II', 'Class III', 'Class IV', 'Class V', 'Class VI', 'Class VII', 'Class VIII', 'Class IX', 'Class X', 'Class XI', 'Class XII'].include?(cell['text'])
          if cell['text_y'].to_f == 291.5
            grade_cells << cell
          end
        elsif ['B', 'G'].include?(cell['text'])
          if cell['text_y'].to_f == 279.5
            bg_cells << cell
          end
        elsif cell['text'] =~ /^\d+$/
          y_coord = cell['text_y'].to_f
          case y_coord
          when 268.5 then ews_cells << cell
          end
        end
      end
    end

    return nil if grade_cells.empty?

    # Sort and filter cells
    [grade_cells, bg_cells].each do |cells|
      cells.sort_by! { |cell| cell['text_x'].to_f }
      # cells.reject! { |cell| cell['text_x'].to_f >= 500 }
    end

    all_data_cells = [
      ews_cells
    ]

    all_data_cells.each do |cells|
      cells.sort_by! { |cell| cell['text_x'].to_f }
      # cells.reject! { |cell| cell['text_x'].to_f >= 500 }
    end

    # Group B,G pairs, ensuring we have complete pairs
    bg_pairs = {}
    bg_cells.each_slice(2) do |pair|
      next unless pair.size == 2 && pair[0] && pair[1]  # Skip incomplete pairs
      b, g = pair
      x_mid = (b['text_x'].to_f + g['text_x'].to_f) / 2
      bg_pairs[x_mid] = [b, g]
    end

    # Match numbers to pairs
    {
      grade_rows: grade_cells,
      bg_pairs: bg_pairs,
      ews_numbers: match_numbers_to_pairs(ews_cells, bg_pairs),
    }
  end

  private
    def match_numbers_to_pairs(remaining_numbers, bg_pairs, threshold = 10.0)
      numbers = {}
      remaining = remaining_numbers.dup

      bg_pairs.each do |x_mid, bg_pair|
        next unless bg_pair && bg_pair.size == 2  # Skip invalid pairs
        b_x = bg_pair[0]['text_x'].to_f
        g_x = bg_pair[1]['text_x'].to_f
        
        # Find numbers closest to B and G positions
        b_num = remaining.find { |cell| (cell['text_x'].to_f - b_x).abs < threshold }
        remaining.delete(b_num) if b_num

        g_num = remaining.find { |cell| (cell['text_x'].to_f - g_x).abs < threshold }
        remaining.delete(g_num) if g_num
        
        numbers[x_mid] = [b_num, g_num]
      end

      numbers
    end
end 