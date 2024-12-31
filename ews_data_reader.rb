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

    sorted_rows = @rows.keys.sort.reverse
    title_index = sorted_rows.index(title_y)
    return unless title_index

    # Find the rows after title
    rows_after_title = sorted_rows[title_index + 1..title_index + 8].map { |y| @rows[y] }

  # Identify rows by their content
    grade_rows = rows_after_title.select { |row| row.any? { |cell| GRADES.include?(cell['text']) } }
    @grades_row = grade_rows.flat_map(&:itself)
    @bg_row = rows_after_title.find { |row| row.any? { |cell| ['B', 'G'].include?(cell['text']) } }
    @values_row = rows_after_title.find { |row| row.any? { |cell| cell['text'] == '-' } }

    # Sort cells within each row by x coordinate
    [@grades_row, @bg_row, @values_row].each do |row|
      next unless row
      row.sort_by! { |cell| cell['text_x'].to_f }
    end

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