class EwsDataReader
  GRADES = [
    'Pre-Pri.', 'Class I', 'Class II', 'Class III', 'Class IV', 'Class V',
    'Class VI', 'Class VII', 'Class VIII', 'Class IX', 'Class X', 'Class XI', 'Class XII'
  ]

  def self.read(csv_path) = new(csv_path).read

  def initialize(csv_path)
    @csv_path = csv_path
    @rows = Hash.new { |h, k| h[k] = [] }
    
    # Group cells by rect_y and rect_x
    CSV.foreach(@csv_path, headers: true) do |cell|
      next unless cell['page'] == '1'

      rect_y = cell['rect_y'].to_f
      @rows[rect_y] << cell
    end

    # Find the title row
    @title_row = @rows.find { |_, cells| cells.any? { |cell| cell&.dig('text')&.include?('Total no. of Economically Weaker Section*(EWS) students Enrolled in Schools') } }
    
    title_y = @title_row&.first
    return unless title_y

    # Find the rows after title
    rows_after_title = @rows.select do |y, cells|
      y < title_y.to_f  # Get all rows below title
    end.sort_by(&:first).reverse

    # First find the grades row
    grades_entry = rows_after_title.find { |_, row| row.any? { |cell| GRADES.include?(cell['text']) } }
    return unless grades_entry
    @grades_row = grades_entry.last
    grades_y = grades_entry.first

    # Then find B/G row below grades
    bg_entry = rows_after_title.find { |y, row| 
      y < grades_y && row.any? { |cell| ['B', 'G'].include?(cell['text']) }
    }
    return unless bg_entry
    @bg_row = bg_entry.last
    bg_y = bg_entry.first

    # Finally find values row below B/G
    values_entry = rows_after_title.find { |y, row| 
      y < bg_y && row.any? { |cell| cell['text'].strip == '-' }
    }
    return unless values_entry
    @values_row = values_entry.last

    # Sort cells within each row by x coordinate and ensure all cells are present
    [@grades_row, @bg_row].each do |row|
      next unless row
      row.sort_by! { |cell| cell['text_x'].to_f }
    end

    # For values row, ensure we have a value for each B/G pair
    if @values_row && @bg_row
      sorted_values = []
      @bg_row.each_slice(2) do |b, g|
        b_x = b['text_x'].to_f
        g_x = g['text_x'].to_f
        
        # Find or create value for boys
        b_val = @values_row.find { |cell| (cell['text_x'].to_f - b_x).abs < 10.0 }
        b_val ||= { 'text' => '-', 'text_x' => b_x }
        sorted_values << b_val
        
        # Find or create value for girls
        g_val = @values_row.find { |cell| (cell['text_x'].to_f - g_x).abs < 10.0 }
        g_val ||= { 'text' => '-', 'text_x' => g_x }
        sorted_values << g_val
      end
      @values_row = sorted_values
    end

    # Normalize empty values to "-"
    @values_row&.each { |cell| cell['text'] = '-' if cell['text'].strip.empty? }

    # Ensure we have all grades
    found_grades = @grades_row.map { |cell| cell['text'] }
    missing_grades = GRADES - found_grades
    if missing_grades.any?
      puts "Warning: Missing grades: #{missing_grades.join(', ')}"
    end

    puts "Title Row: #{@title_row[1].map { |cell| cell['text'] }}"
    puts "Grades Row: #{@grades_row&.map { |cell| cell['text'] }}"
    puts "BG Row: #{@bg_row&.map { |cell| cell['text'] }}"
    puts "values Row: #{@values_row&.map { |cell| cell['text'] }}"
  end

  def read
    return nil unless @grades_row && @bg_row && @values_row

    # Group B,G pairs, ensuring we have complete pairs
    bg_pairs = {}
    @bg_row.each_slice(2) do |pair|
      next unless pair.size == 2 && pair[0] && pair[1]  # Skip incomplete pairs
      b, g = pair
      x_mid = (b['text_x'].to_f + g['text_x'].to_f) / 2
      bg_pairs[x_mid] = [b, g]
    end

    # Match numbers to pairs
    {
      grade_rows: @grades_row,
      bg_pairs: bg_pairs,
      ews_numbers: match_numbers_to_pairs(@values_row, bg_pairs),
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