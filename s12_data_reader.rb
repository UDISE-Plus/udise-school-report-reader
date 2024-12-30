class S12DataReader
  def self.read(csv_path) = new(csv_path).read

  def initialize(csv_path) = @csv_path = csv_path

  def read
    # Initialize arrays for different row types
    grade_rows = []
    bg_rows = []
    s12_rows = []

    CSV.foreach(@csv_path, headers: true) do |row|
      if row['page'] == '1'
        if ['Pre-Pri.', 'Class I', 'Class II', 'Class III', 'Class IV', 'Class V', 'Class VI', 'Class VII', 'Class VIII'].include?(row['text'])
          if row['text_y'].to_f == 341.5
            grade_rows << row
          end
        elsif ['B', 'G'].include?(row['text'])
          if row['text_y'].to_f == 329.5
            bg_rows << row
          end
        elsif row['text'] =~ /^\d+$/
          y_coord = row['text_y'].to_f
          case y_coord
          when 318.5 then s12_rows << row
          end
        end
      end
    end

    return nil if grade_rows.empty?

    # Sort and filter rows
    [grade_rows, bg_rows].each do |rows|
      rows.sort_by! { |row| row['text_x'].to_f }
    end

    all_data_rows = [
      s12_rows
    ]

    all_data_rows.each do |rows|
      rows.sort_by! { |row| row['text_x'].to_f }
    end

    # Group B,G pairs, ensuring we have complete pairs
    bg_pairs = {}
    bg_rows.each_slice(2) do |pair|
      next unless pair.size == 2 && pair[0] && pair[1]  # Skip incomplete pairs
      b, g = pair
      x_mid = (b['text_x'].to_f + g['text_x'].to_f) / 2
      bg_pairs[x_mid] = [b, g]
    end

    # Match numbers to pairs
    {
      grade_rows: grade_rows,
      bg_pairs: bg_pairs,
      s12_numbers: match_numbers_to_pairs(s12_rows, bg_pairs),
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
        b_num = remaining.find { |row| (row['text_x'].to_f - b_x).abs < threshold }
        remaining.delete(b_num) if b_num

        g_num = remaining.find { |row| (row['text_x'].to_f - g_x).abs < threshold }
        remaining.delete(g_num) if g_num
        
        numbers[x_mid] = [b_num, g_num]
      end

      numbers
    end
end 